    bits 64
    section .text

    ;; LibC
    extern stat
    extern open, close
    extern mmap, munmap
    extern malloc, free
    extern write, printf

    global main
main:
    push r15                    ; Will contain the char* map used to print
    push r14                    ; Will contain the int* map used to work
    push r13                    ; Will contain the size of the map
    push r12                    ; will contain the size of line
    push rbx                    ; Will contain argv in a first time, then idk
    sub rsp, 168                ; Will contain at:
                                ;; rsp    -> beginning of the file
                                ;; rsp+8  -> struct stat st
                                ;; rsp+56 -> st.st_size

    mov rbx, rsi                ; saves av
    mov QWORD [rsp+160], rsi    ; tmp av

    ;; Retrieving file's size.
    mov rdi, rsp
    add rdi, 8
    mov rsi, rdi                ; prep rsi with st for stat call

    ;; prep rep stosq to memset 0 st
    xor eax, eax
    mov ecx, 18
    rep stosq                   ; fill rdi ecx times with eax

    mov rdi, [rbx+8]            ; av[1]
    call stat WRT ..plt
    cmp rax, -1
    mov rax, 1                  ; prepare for error return
    je .ret

    mov r13, QWORD [rsp+56]     ; Will work with this size.

    ;; Open file.
    xor rsi, rsi                ; O_RDONLY == 0
    call open WRT ..plt
    cmp rax, -1
    mov r8, rax                 ; Save fd in mmap register
    mov rax, 1                  ; prepare for error return
    je .ret

    ;; Mmap file
    xor rdi, rdi                ; hint addr = 0
    mov rsi, r13                ; size
    mov rdx, 0x3                ; PROT_READ | PROT_WRITE
    mov rcx, 0x2                ; MAP_PRIVATE
    xor r9, r9                  ; offset = 0
    call mmap WRT ..plt

    mov QWORD [rsp], rax        ; Save beginning of the file
    mov r15, rax                ; Save print map

    ;; Close file
    mov rdi, r8
    call close WRT ..plt

    cmp r15, -1                 ; Check if mmap failed
    je .ret

.RemoveFirstLine:
    add r15, 1
    sub r13, 1
    cmp BYTE [r15 - 1], 10          ; '\n'
    jne .RemoveFirstLine

    ;; Allocate work map
    mov rax, r13
    mov rcx, 4
    mul rcx                     ; rax * 4 -> size * sizeof(int)

    mov rdi, rax
    call malloc WRT ..plt

    mov r14, rax
    cmp r14, 0
    je .MunmapFile

    ;; Setup first line
    mov rcx, -1
    xor r8, r8

.convertFirstLine:
    add rcx, 1
    movzx eax, BYTE [r15 + rcx]

    ;; Convert current position
    cmp al, 46                  ; '.'
    sete r8b
    movzx r8d, r8b
    mov DWORD [r14 + 4*rcx], r8d ; work[rcx] = print[rcx] == '.'

    cmp al, 10                  ; '\n'
    jne .convertFirstLine

    ;; Begin BSQ algo
    mov r12, rcx                ; save line size
    xor r10, r10                ; Will contain best index
    xor r11d, r11d              ; will contain best value

.BSQ:
    add rcx, 1
    cmp rcx, r13
    je .FreeWorkMap

    ;; Convert current position
    movzx eax, BYTE [r15 + rcx]
    cmp al, 46                  ; '.'
    sete r8b
    movzx r8d, r8b
    mov DWORD [r14 + 4*rcx], r8d ; work[rcx] = print[rcx] == '.'
    jne .BSQ                     ; print[rcx] == ' ' || print[rcx] = '\n' -> continue

    ;; if !(rcx % line len) -> continue
    mov rax, rcx
    xor edx, edx
    div r12
    cmp edx, 0
    je .BSQ

    ;; Position's value calculation
    mov rbx, rcx
    sub rbx, r12                ; i - line len

    ;; min = work[rcx-1]
    mov eax, DWORD [r14 + 4*rcx - 4]

    ;; if work[rcx-linelen] < min -> min = work[..]
    cmp DWORD [r14 + 4*rbx], eax
    cmovle eax, DWORD [r14 + 4*rbx]

    ;; if work[rcx-linelen-1] < min -> min = work[..]
    cmp DWORD [r14 + 4*rbx - 4], eax
    cmovle eax, DWORD [r14 + 4*rbx - 4]

    ;; r14[++i] = min
    add eax, 1
    mov DWORD [rdi + 4*rcx], eax

    ;; Is new best sqr?
    cmp eax, r11d
    jle .BSQ

    ;; Yes, save
    mov r11d, eax
    mov r10, rcx
    jmp .BSQ

.FreeWorkMap:
    mov rdi, r14
    call free WRT ..plt

    ;; Set square in print map
    ;; rdi = r15 + r10 - r12
    ;; for (int rcx = 0; rcx != r11d; rcx += 1) {
    ;;      memset(rdi, 'x', r11d)
    ;;      rdi -= r12
    ;; }
    ;; Setup memset registers

    mov rdi, QWORD [rsp+160]
    mov rdi, QWORD [rdi+16]
    mov rsi, r11
    mov rdx, r10
    call printf WRT ..plt
    ;;     mov rdi, r15
;;     add rdi, r10

;;     mov ecx, -1
;; .SquareLoop:
;;     sub rdi, r11
;;     add ecx, 1
;;     cmp ecx, r11d
;;     je .PrintMap

;;     mov rdx, -1
;; .SquareFill:
;;     add rdx, 1
;;     mov BYTE [rdi + rdx], 120   ; 'x'
;;     cmp rdx, r11
;;     jne .SquareFill

;;     add rdi, rdx
;;     sub rdi, r12
;;     jmp .SquareLoop

.PrintMap:
    mov edi, 1
    mov rsi, r15
    mov rdx, r13
    call write WRT ..plt

.MunmapFile:
    mov rdi, QWORD [rsp]
    mov rsi, QWORD [rsp+56]
    call munmap WRT ..plt
    xor rax, rax

.ret:
    add rsp, 168
    pop rbx
    pop r12
    pop r13
    pop r14
    pop r15
    ret
