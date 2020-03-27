    bits 64
    section .text

    ;; LibC
    extern stat
    extern puts
    extern printf

    global main
main:
    push rbx
    mov rbx, rsi                ; save av -- TMP

    mov rdi, QWORD [rbx+8]           ; av[1]
    call get_filesz

    mov r10, rax                ; size
    cmp r10, 1
    je .ret

    mov rdi, [rbx+16]
    mov rsi, r10
    call printf WRT ..plt
    xor rax, rax

.ret:
    pop rbx
    ret


    ;; Returns the size of the file described by filepath
    ;; rdi = char const *fp
    ;; rax -> filesz | 1 if any error
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
    mov eax, 1
    cmovne rax, QWORD [rsp+48]  ; mov if not equal

    add rsp, 152
    ret

