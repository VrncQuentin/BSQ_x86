    bits 64
    section .text

    ;; LibC
    extern munmap
    extern malloc, free
    extern puts, printf

    ;; Internals
    extern get_filesz
    extern get_file
    ;; Naming Informations:
    ;; symbols starting with _ -> function which will be moved later
    ;; symbols starting with . -> function internals

    ;; Variables Informations:
    ;; rsp   = raw map (kept for munmap)
    ;; rsp+8 = raw size (kept for munmap)
    ;; rbx = argv (only until _get_file call)
    ;; r15 = print map (raw shifted)
    ;; r14 = work map
    ;; r13 = work size
    ;; r12 = line size
    ;; r11 = best val
    ;; r10 = best index

    global main
main:
    push rbx
    sub rsp, 24
    mov rbx, rsi                ; save av

    ;; Retrieve file size
    mov rdi, QWORD [rbx+8]      ; av[1]
    call get_filesz

    mov [rsp+8], rax            ; save raw size
    mov r13, rax                ; save work size
    cmp rax, -1
    je .ret

    ;; Retrieve file
    mov rdi, QWORD [rbx+8]
    mov rsi, [rsp+8]
    call get_file

    cmp rax, 0
    mov [rsp], rax              ; save raw map
    mov r15, rax                ; save print map
    je .ret

    ;; remove first line
    mov r8, 10                  ; '\n'
.rm_first_line:
    add r15, 1
    sub r13, 1
    cmp r8b, BYTE [r15]
    jne .rm_first_line

    add r15, 1
    sub r13, 1

    ;; alloc int map
    mov rax, r13
    mov rcx, 4
    mul rcx
    mov rdi, rax
    call malloc WRT ..plt

    mov r14, rax                ; save work map
    cmp r14, 0
    je .free_file

    mov rcx, -1
    mov rdi, r14
    mov rsi, r15

    ;; convert first line
.convert_first_line:
    add rcx, 1
    movzx eax, BYTE [rsi + rcx]
    cmp al, 46                  ; '.'
    jne .obstacle_cfl

    mov DWORD [rdi + 4 * rcx], 1
    jmp .convert_first_line

.obstacle_cfl:
    cmp al, 111                 ; 'o'
    jne .begin_bsq

    mov DWORD [rdi + 4 * rcx], 0
    jmp .convert_first_line

.begin_bsq:
    mov r12, rcx                ; save line size
    add r12, 1
    xor r11, r11                ; prep best index

    ;; reached '\n' of first line
    ;; convert the rest while resolving
.bsq:
    add rcx, 1
    cmp rcx, r13
    je .free_intmap

    movzx eax, BYTE [rsi + rcx]
    cmp al, 46                  ; '.'
    je .algo_bsq

    mov DWORD [rdi + 4 * rcx], 0     ; either I'm on 'o' or '\n'
    jmp .bsq

.algo_bsq:
    ;; !(rcx%line_len) -> continue
    xor edx, edx
    mov rax, rcx
    mov rbx, r12
    div rbx                     ; edx contains modulus
    cmp edx, 0
    je .bsq

    ;; find min
;;     mov eax, DWORD [rdi - 4]
;;     mov r8d, DWORD [rdi - 0 + 4*r12]

;;     cmp eax, r8d
;;     jg .scd_check

;;     mov eax, r8d
;; .scd_check:
;;     mov r8d, DWORD [rdi - 4 + 4*r12]
;;     cmp eax, r8d
;;     jg .end_check

;;     mov eax, r8d
;; .end_check:
;;     add eax, 1
;;     mov DWORD [rdi + 4*rcx], eax

;;     cmp eax, r11d
;;     jl .bsq

;;     mov r11d, eax
;;     mov r10, rcx
    jmp .bsq

    ;; put sqr in print map
.free_intmap:
    mov rdi, r14
    call free WRT ..plt

.end_bsq:
    mov r8, r12
    sub r8, r11
    add r8, 1

    mov rdi, r15
    add rdi, r10                ; used to put the 'x'
    add rdi, r8
    mov rdx, -1                 ; line counter (y)

.next_line_sqr:
    add rdx, 1
    cmp rdx, r11
    je .print_file
    mov rcx, -1                 ; col counter (x)
    sub rdi, r8

.next_col_sqr:
    sub rdi, 1
    add rcx, 1
    cmp rcx, r11
    je .next_line_sqr

     ;; mov BYTE [rdi], 120         ; 'x'
    jmp .next_col_sqr
    ;; display map & end
.print_file:
    mov rdi, r15
    call puts WRT ..plt

.free_file:
    mov rdi, [rsp]
    mov rsi, [rsp+8]
    call munmap WRT ..plt

.ret:
    xor rax, rax
    add rsp, 24
    pop rbx
    ret
