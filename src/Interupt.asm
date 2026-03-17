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

        ret

        .read_char:         ; AH = 01h: Read character with echo
            call _getchar   ; Result is returned in EAX (AL)
        ret

        .print_char:        ; AH = 02h: Write character to STDOUT
            push eax        ; Save EAX to preserve AH

            and edx, 0xFF   ; Ensure only the character in DL is passed
            push edx
            call _putchar
            add esp, 4
            
            mov ah, byte [esp + 1] ; Restore AH from the stack
            add esp, 4         
        ret

        .print_string:      ; AH = 09h: Write string to STDOUT
            ; Note: To support standard DOS '$' termination, 
            ; a loop converting '$' to null (0) would be required.
            pushad
            push edx        ; EDX contains the string pointer
            call _printf
            add esp, 4
            popad
        ret

        .buffer_input:      ; AH = 0Ah: Buffered string input
            pushad          ; Save all general-purpose registers

            sub esp, 128    ; Allocate 128-byte local buffer on the stack
            mov ebp, esp    ; Set EBP as a pointer to the local buffer
            mov ebx, ebp    ; Keep a copy of the buffer start address

            ; Prepare arguments for scanf("%s%n", local_buffer, &int21_buff_n)
            push int21_buff_n     ; Argument 3: length pointer
            push ebp              ; Argument 2: local buffer address
            push int21_fmt_input  ; Argument 1: format string
            
            call _scanf
            add esp, 12           ; Clean up scanf arguments

            ; Calculate address of original EDX passed via pushad
            ; Current ESP + local buffer (128) + offset to EDX in pushad (20) = 148
            mov ebp, esp
            add ebp, 148
            mov edx, [ebp]        ; EDX now points to the original DOS buffer

            ; 1. Store the actual number of characters read
            mov eax, [int21_buff_n]
            mov [edx + 1], al     ; Set 'actual length' byte
            
            ; 2. Determine bytes to copy (clamp to max buffer size)
            mov ah, al            ; Current length
            mov al, [edx]         ; Max length defined by user
            cmp al, ah
            jna .ifNAbove
            mov al, ah            ; If actual > max, use max
            .ifNAbove:

            ; 3. Copy characters from stack to DOS buffer
            mov edi, edx        
            add edi, 2            ; EDI = destination (DOS buffer content start)
            mov esi, esp          ; ESI = source (local stack buffer)
            
            xor ecx, ecx
            mov cl, al            ; Number of bytes to copy
            rep movsb             ; Copy string from ESI to EDI

            add esp, 128          ; Release local stack buffer
            
            ; --- Cleanup ---
            ; Temporary fix for the leftover newline in stdin. 
            ; Note: This handles Enter but may cause issues if input contains spaces.
            call _getchar         
            popad                 ; Restore all registers
        ret         

        .error:
            push int21_err_msg
            call _printf 
            add esp, 4
            ; Fall through to exit

        .exit:
            and eax, 0xFF         ; Use only AL for exit code
            push eax
            call _exit