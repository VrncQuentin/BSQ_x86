    bits 64
    section .text

    ;; LibC
    extern stat
    extern open, close
    extern mmap, munmap
    extern puts, printf

    ;; Naming Information:
    ;; symbols starting with _ -> function which will be moved later
    ;; symbols starting with . -> function internals

    ;; Registry Information:
    ;; rbx = argv
    ;; r15 = raw size (kept for munmap)
    ;; r14 = raw map (kept for munmap)
    ;; r13 = print map (raw shifted)
    ;; r12 = work map
    ;; r11 = work size

    global main
main:
    push rbx
    mov rbx, rsi                ; save av

    ;; Retrieve file size
    mov rdi, QWORD [rbx+8]           ; av[1]
    call _get_filesz

    mov r15, rax                ; save raw size
    cmp r15, 1
    je .ret

    ;; Retrieve file
    mov rdi, QWORD [rbx+8]
    mov rsi, r15
    call _get_file

    cmp rax, 0
    mov r14, rax                ; save raw map
    mov r13, rax                ; save print map
    mov rax, 1
    je .ret

.print_file:
    mov rdi, r14
    call puts WRT ..plt
    xor rax, rax

.free_map:
    mov rdi, r14
    mov rsi, r15
    call munmap WRT ..plt

.ret:
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

