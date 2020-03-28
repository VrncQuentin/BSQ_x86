    bits 64
    section .text

    extern open, close
    extern mmap

    global get_file
    ;; Returns a pointer to the file
    ;; rdi = char const *fp
    ;; rsi = size_t sz
    ;; rax -> ptr to file | NULL if any error
get_file:
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
