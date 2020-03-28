    bits 64
    section .text

    extern stat
    ;; Returns the size of the file described by filepath
    ;; rdi = char const *fp
    ;; rax -> filesz | 1 if any error
    global get_filesz
get_filesz:
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
    cmovne rax, QWORD [rsp+48]  ; mov if not equal

    add rsp, 152
    ret
