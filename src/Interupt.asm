; MTECH_INT_DOS
; =============
;
; A minimal educational DOS interrupt emulator for x86 (32-bit),
; built as a wrapper for C Standard Library functions.
;
; Designed for teaching Computer Architecture at Montana Tech.
; NASM 32-bit MS COFF | Target: interupt.obj
;
; MIT License
; Copyright (c) 2026
; J.L. Pach, Montana Technological University

global _interupt_21h ; 32-bit MS COFF

extern  _printf
extern  _scanf
extern  _getchar
extern  _putchar
extern  _exit

section .data

    ; Internal INT 21h variables
    int21_fmt_input  db "%s%n", 0      
    int21_buff_n     dd 0
    int21_err_msg    db "INT21h: unsupported AH", 13, 10, 0

section .text
    _interupt_21h:
        ; Dispatcher based on AH value
        cmp ah, 0
        je .exit

        cmp ah, 1        
        je .read_char

        cmp ah, 2
        je .print_char

        cmp ah, 9
        je .print_string

        cmp ah, 10
        je .buffer_input

        cmp ah, 4Ch
        je .exit

        jmp .error

        .read_char:         ; AH = 01h: Read character with echo
            add rsp, 40
            call _getchar   ; Result is returned in RAX (AL)
            sub rsp, 40
        ret

        .print_char:        ; AH = 02h: Write character to STDOUT
            push rax        ; Save RAX to preserve AH
            push rcx

            and edx, 0xFF   ; Ensure only the character in DL is passed
            mov rcx, rdx
            sub rsp, 32
            call _putchar
            add rsp, 32
            
            pop rcx
            pop rax         ; Restore AH from the stack      
        ret

        .print_string:      ; AH = 09h: Write string to STDOUT
            ; Note: To support standard DOS '$' termination, 
            ; a loop converting '$' to null (0) would be required.
            push rax        ; pushad does not work in real mode, mimic it
            push rcx
            push rdx
            push rbx
            push rbp
            push rsi
            push rdi

            mov rcx, rdx        ; EDX contains the string pointer
            call _printf

            pop rdi         ; popad does not work in real mode
            pop rsi
            pop rbp
            pop rbx
            pop rdx
            pop rcx
            pop rax
        ret

        .buffer_input:      ; AH = 0Ah: Buffered string input
            push rax        ; pushad does not work in real mode, mimic it
            push rcx
            push rdx
            push rbx
            push rbp
            push rsi
            push rdi

            sub rsp, 128    ; Allocate 128-byte local buffer on the stack
            mov rbp, rsp    ; Set EBP as a pointer to the local buffer
            mov rbx, rbp    ; Keep a copy of the buffer start address

            ; Prepare arguments for scanf("%s%n", local_buffer, &int21_buff_n)
            mov rcx, int21_fmt_input  ; Argument 1: format string
            mov rdx, rbp              ; Argument 2: local buffer address
            mov r8, int21_buff_n     ; Argument 3: length pointer
            
            call _scanf

            ; Calculate address of original EDX passed via pushad
            ; Current RSP + local buffer (128) + offset to RDX in pushad (32) = 160
            mov rbp, rsp
            add rbp, 160
            mov rdx, [rbp]        ; EDX now points to the original DOS buffer

            ; 1. Store the actual number of characters read
            mov rax, [int21_buff_n]
            mov [rdx + 1], al     ; Set 'actual length' byte
            
            ; 2. Determine bytes to copy (clamp to max buffer size)
            mov ah, al            ; Current length
            mov al, [rdx]         ; Max length defined by user
            cmp al, ah
            jna .ifNAbove
            mov al, ah            ; If actual > max, use max
            .ifNAbove:

            ; 3. Copy characters from stack to DOS buffer
            mov rdi, rdx        
            add rdi, 2            ; RDI = destination (DOS buffer content start)
            mov rsi, rsp          ; RSI = source (local stack buffer)
            
            xor rcx, rcx
            mov cl, al            ; Number of bytes to copy
            rep movsb             ; Copy string from RSI to RDI

            add rsp, 128          ; Release local stack buffer
            
            ; --- Cleanup ---
            ; Temporary fix for the leftover newline in stdin. 
            ; Note: This handles Enter but may cause issues if input contains spaces.
            call _getchar         
            pop rdi               ; popad does not work in real mode     
            pop rsi
            pop rbp
            pop rbx
            pop rdx
            pop rcx
            pop rax
        ret         

        .error:
            push int21_err_msg
            call _printf 
            add rsp, 8
            ; Fall through to exit

        .exit:
            and rax, 0xFF         ; Use only AL for exit code
            push rax
            call _exit