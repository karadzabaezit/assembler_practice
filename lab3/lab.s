%define MAX_WORD_LEN 4096

section .data
    usage_msg       db "Usage: program N filename", 10
    usage_len       equ $-usage_msg
    err_open        db "Error opening file", 10
    err_open_len    equ $-err_open
    err_read        db "Error reading file", 10
    err_read_len    equ $-err_read
    err_num         db "Invalid N (must be non-negative integer)", 10
    err_num_len     equ $-err_num
    err_word_len    db "Word too long (exceeds 1MB)", 10
    err_word_len_len equ $-err_word_len
    space           db " "
    newline         db 10

section .bss
    word_buffer     resb 1048576
    char_buf        resb 1

section .text
global _start

_start:
    mov rdi, [rsp]
    cmp rdi, 3
    je .args_ok
    mov rsi, usage_msg
    mov rdx, usage_len
    call write_stderr
    mov rdi, 1
    mov rax, 60
    syscall

.args_ok:
    mov rsi, [rsp+16]
    call atoi
    mov r12, rax

    mov rdi, [rsp+24]
    mov rsi, 0
    mov rax, 2
    syscall
    test rax, rax
    js .open_error
    mov r8, rax

    xor r13, r13
    xor r14, r14
    xor r15, r15

.read_loop:
    mov rax, 0
    mov rdi, r8
    mov rsi, char_buf
    mov rdx, 1
    syscall
    cmp rax, 0
    je .end_of_file
    jl .read_error

    movzx rcx, byte [char_buf]

    cmp rcx, 10
    je .handle_newline
    cmp rcx, 32
    je .handle_delim
    cmp rcx, 9
    je .handle_delim

    cmp r13, 0
    je .start_word
    cmp r15, MAX_WORD_LEN
    jge .word_too_long
    mov rsi, word_buffer
    add rsi, r15
    mov [rsi], cl
    inc r15
    jmp .read_loop

.start_word:
    cmp r14, 1
    jne .no_space
    mov r9, rcx
    mov rax, 1
    mov rdi, 1
    mov rsi, space
    mov rdx, 1
    syscall
    mov rcx, r9
    xor r14, r14
.no_space:
    cmp r15, MAX_WORD_LEN
    jge .word_too_long
    mov rsi, word_buffer
    add rsi, r15
    mov [rsi], cl
    inc r15
    mov r13, 1
    jmp .read_loop

.handle_delim:
    cmp r13, 0
    je .read_loop
    call output_word
    mov r14, 1
    jmp .read_loop

.handle_newline:
    cmp r13, 0
    je .just_newline
    call output_word
.just_newline:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    xor r14, r14
    xor r13, r13
    xor r15, r15
    jmp .read_loop

.end_of_file:
    cmp r13, 1
    jne .close_file
    call output_word
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

.close_file:
    mov rax, 3
    mov rdi, r8
    syscall
    xor rdi, rdi
    mov rax, 60
    syscall

.open_error:
    mov rsi, err_open
    mov rdx, err_open_len
    call write_stderr
    mov rdi, 1
    mov rax, 60
    syscall

.read_error:
    mov rsi, err_read
    mov rdx, err_read_len
    call write_stderr
    mov rax, 3
    mov rdi, r8
    syscall
    mov rdi, 1
    mov rax, 60
    syscall

.word_too_long:
    mov rsi, err_word_len
    mov rdx, err_word_len_len
    call write_stderr
    mov rax, 3
    mov rdi, r8
    syscall
    mov rdi, 1
    mov rax, 60
    syscall

output_word:
    cmp r15, 0
    je .done

    mov rax, r12
    xor rdx, rdx
    div r15
    mov r10, rdx
    test r10, r10
    jz .full_output

    mov rdi, 1
    mov rsi, word_buffer
    add rsi, r15
    sub rsi, r10
    mov rdx, r10
    mov rax, 1
    syscall

    mov rsi, word_buffer
    mov rdx, r15
    sub rdx, r10
    test rdx, rdx
    jz .done
    mov rax, 1
    syscall
    jmp .done

.full_output:
    mov rdi, 1
    mov rsi, word_buffer
    mov rdx, r15
    mov rax, 1
    syscall

.done:
    xor r15, r15
    mov r13, 0
    ret

atoi:
    xor rax, rax
    xor rcx, rcx
.loop:
    movzx rdx, byte [rsi+rcx]
    test rdx, rdx
    jz .done
    cmp rdx, '0'
    jb .invalid
    cmp rdx, '9'
    ja .invalid
    sub rdx, '0'
    imul rax, rax, 10
    add rax, rdx
    inc rcx
    jmp .loop
.done:
    ret
.invalid:
    mov rsi, err_num
    mov rdx, err_num_len
    call write_stderr
    mov rdi, 1
    mov rax, 60
    syscall

write_stderr:
    mov rax, 1
    mov rdi, 2
    syscall
    ret