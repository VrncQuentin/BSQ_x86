    bits 64
    section .text

    ;; LibC
    extern stat
    extern open, close
    extern mmap, munmap
    extern malloc, free
    extern puts, printf

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
    ;; r11 = best index

    global main
main:
    push rbx
    sub rsp, 24
    mov rbx, rsi                ; save av

    ;; Retrieve file size
    mov rdi, QWORD [rbx+8]      ; av[1]
    call _get_filesz

    mov [rsp+8], rax            ; save raw size
    mov r13, rax                ; save work size
    cmp rax, 1
    je .ret

    ;; Retrieve file
    mov rdi, QWORD [rbx+8]
    mov rsi, [rsp+8]
    call _get_file

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

    ;; convert first line
.convert_first_line:
    add rcx, 1
    movzx eax, BYTE [r15 + rcx]
    cmp al, 46                  ; '.'
    jne .obstacle_cfl

    mov BYTE [r14 + rcx], 1
    jmp .convert_first_line

.obstacle_cfl:
    cmp al, 111                 ; 'o'
    jne .end_cfl

    mov BYTE [r14 + rcx], 0
    jmp .convert_first_line

.end_cfl:
    mov r12, rcx
    add r12, 1

    ;; reached '\n' of first line
    ;; convert the rest while resolving
.bsq:
    add rcx, 1
    cmp rcx, 13
    je .end_bsq

    movzx eax, BYTE [r15 + rcx]
    cmp al, 46                  ; '.'
    je .algo_bsq

    mov BYTE [r14 + rcx], 0     ; either I'm on 'o' or '\n'
    jmp .bsq

.algo_bsq:
    mov BYTE [r14 + rcx], 1

    ;; !(rcx%line_len) -> continue
    xor edx, edx
    mov rax, rcx
    mov rbx, r12
    div rbx                     ; edx contains modulus
    cmp edx, 0
    je .bsq

    ;; find min
    
.end_bsq:
    ;; put sqr in print map
    ;; display map & end
.print_file:
    mov rdi, r15
    call puts WRT ..plt

.free_intmap:
    mov rdi, r14
    call free WRT ..plt

.free_file:
    mov rdi, [rsp]
    mov rsi, [rsp+8]
    call munmap WRT ..plt

.ret:
    xor rax, rax
    add rsp, 24
    pop rbx
    ret

    ;; Returns a pointer to the file
    ;; rdi = char const *fp
    ;; rsi = size_t sz
    ;; rax -> ptr to file | NULL if any error
_get_file:
    mov r9, rsi

    xor rsi, rsi           ; O_RDONLY == 0
    call open WRT ..plt

    cmp rax, -1
    mov r8, rax                ; save fd
    jne .mmapfile

    xor rax, rax
    ret

.mmapfile:
    xor rdi, rdi
    mov rsi, r9
    mov rdx, 0x1           ; PROT_READ
    mov rcx, 0x2           ; MAP_PRIVATE
    xor r9, r9             ; fd is alrdy in r8
    call mmap WRT ..plt
    mov r8, rax

    mov rdi, r9
    call close WRT ..plt

    mov rax, r8
    ret
    ;; Returns the size of the file described by filepath
    ;; rdi = char const *fp
    ;; rax -> filesz | 1 if any error
_get_filesz:
    sub rsp, 152
    mov r8, rdi                 ; save fp
    mov rsi, rsp                ; prep rsi for stat

    ;; struct stat st = {0}
    mov rdi, rsp
    xor eax, eax
    mov ecx, 18
    rep stosq                   ; memset rdi ecx times with eax

    mov rdi, r8
    call stat WRT ..plt

    cmp eax, -1                 ; if (stat == -1) rax = 1 else st.st_size
    mov eax, 1
    cmovne rax, QWORD [rsp+48]  ; mov if not equal

    add rsp, 152
    ret

