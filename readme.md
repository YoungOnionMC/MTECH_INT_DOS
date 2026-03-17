![MTECH_GPIO](logo.png)

---

# MTECH_INT_DOS

A minimal educational DOS interrupt emulator for x86 (32-bit) assembly, designed for teaching Computer Architecture at **Montana Technological University**.

This library acts as a bridge between classic DOS-style programming and modern Windows systems. It provides a familiar interface (`int 21h`) by wrapping standard C library functions (MSVCRT).

## Features

- **NASM 32-bit MS COFF** compatibility.
- Seamless integration with **lld-link**.
- Support for common DOS functions:
    - `AH=00h`: Program termination.
    - `AH=01h`: Read character with echo.
    - `AH=02h`: Write character to STDOUT.
    - `AH=09h`: Write string to STDOUT.
    - `AH=0Ah`: Buffered string input (DOS buffer structure).
    - `AH=4Ch` / `AH=00h`: Program termination.

## Getting Started

### 1. Build the Library
Use the provided `Makefile` to generate the object file. It is crucial to use the `-g -F cv8` flags with NASM to ensure PDB generation for debugging.

```bash
mingw32-make
```

## License

MIT License © 2026 Jakub Leszek Pach, Montana Technological University

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

The software is provided "as is", without warranty of any kind. The author is not responsible for any damage or malfunction resulting from its use.