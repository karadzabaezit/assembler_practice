%define SYS_READ    0
%define SYS_WRITE   1
%define SYS_OPEN    2
%define SYS_CLOSE   3
%define SYS_EXIT    60
%define STDOUT      1
%define STDERR      2
%define BUF_SIZE    4096
%define WORD_MAX    4095

section .data
    err_usage   db "Usage: ./lab3 <input_file> <N>", 10
    err_usage_l equ $ - err_usage
    err_open    db "Error: cannot open input file", 10
    err_open_l  equ $ - err_open
    err_word    db "Error: word exceeds 4095 characters", 10
    err_word_l  equ $ - err_word
    err_n       db "Error: N must be a non-negative integer", 10
    err_n_l     equ $ - err_n
    ch_space    db " "
    ch_nl       db 10

section .bss
    read_buf    resb BUF_SIZE
    word_buf    resb BUF_SIZE
    out_buf     resb BUF_SIZE

section .text
    global _start

_start:
    pop     rax
    cmp     rax, 3
    jne     die_usage

    pop     rcx
    pop     rsi
    pop     rdx

    mov     rdi, rdx
    call    parse_uint
    cmp     rax, -1
    je      die_n
    mov     r15, rax

    mov     rax, SYS_OPEN
    mov     rdi, rsi
    xor     esi, esi
    xor     edx, edx
    syscall
    cmp     rax, 0
    jl      die_open
    mov     r14, rax

    xor     rbx, rbx
    xor     r12, r12
    xor     r13, r13

read_loop:
    mov     rax, SYS_READ
    mov     rdi, r14
    lea     rsi, [rel read_buf]
    mov     rdx, BUF_SIZE
    syscall
    cmp     rax, 0
    jl      read_loop
    je      on_eof
    mov     rbp, rax
    xor     r9, r9

parse_loop:
    cmp     r9, rbp
    jge     read_loop
    movzx   eax, byte [read_buf + r9]
    inc     r9
    cmp     al, 10
    je      on_newline
    cmp     al, 32
    je      on_sep
    cmp     al, 9
    je      on_sep

on_char:
    cmp     rbx, WORD_MAX
    jge     die_word
    mov     [word_buf + rbx], al
    inc     rbx
    jmp     parse_loop

on_sep:
    call    emit_word
    jmp     parse_loop

on_newline:
    call    emit_word
    call    emit_newline
    jmp     parse_loop

on_eof:
    call    emit_word
    cmp     r12, 0
    je      close_exit
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    lea     rsi, [rel ch_nl]
    mov     rdx, 1
    syscall

close_exit:
    mov     rax, SYS_CLOSE
    mov     rdi, r14
    syscall
    mov     rax, SYS_EXIT
    xor     edi, edi
    syscall

emit_word:
    cmp     rbx, 0
    je      ew_done
    cmp     r12, 0
    je      ew_no_space
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    lea     rsi, [rel ch_space]
    mov     rdx, 1
    syscall
ew_no_space:
    mov     rdi, rbx
    call    rotate_write
    inc     r12
    xor     rbx, rbx
ew_done:
    ret

emit_newline:
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    lea     rsi, [rel ch_nl]
    mov     rdx, 1
    syscall
    xor     r12, r12
    inc     r13
    ret

rotate_write:
    push    r10
    push    r11

    mov     r10, rdi
    cmp     r10, 0
    je      rw_done

    mov     rax, r15
    xor     edx, edx
    div     r10
    mov     r11, rdx

    cmp     r11, 0
    je      rw_no_rotate

    lea     rsi, [rel word_buf]
    add     rsi, r10
    sub     rsi, r11
    lea     rdi, [rel out_buf]
    mov     rcx, r11
    rep     movsb

    lea     rsi, [rel word_buf]
    lea     rdi, [rel out_buf]
    add     rdi, r11
    mov     rcx, r10
    sub     rcx, r11
    rep     movsb

    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    lea     rsi, [rel out_buf]
    mov     rdx, r10
    syscall
    jmp     rw_done

rw_no_rotate:
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    lea     rsi, [rel word_buf]
    mov     rdx, r10
    syscall

rw_done:
    pop     r11
    pop     r10
    ret

parse_uint:
    xor     rax, rax
    xor     rcx, rcx
pu_loop:
    movzx   edx, byte [rdi + rcx]
    cmp     dl, 0
    je      pu_check
    cmp     dl, '0'
    jl      pu_err
    cmp     dl, '9'
    jg      pu_err
    imul    rax, rax, 10
    sub     edx, '0'
    add     rax, rdx
    inc     rcx
    jmp     pu_loop
pu_check:
    cmp     rcx, 0
    je      pu_err
    ret
pu_err:
    mov     rax, -1
    ret

die_usage:
    mov     rax, SYS_WRITE
    mov     rdi, STDERR
    lea     rsi, [rel err_usage]
    mov     rdx, err_usage_l
    syscall
    mov     rax, SYS_EXIT
    mov     edi, 1
    syscall

die_open:
    mov     rax, SYS_WRITE
    mov     rdi, STDERR
    lea     rsi, [rel err_open]
    mov     rdx, err_open_l
    syscall
    mov     rax, SYS_EXIT
    mov     edi, 1
    syscall

die_n:
    mov     rax, SYS_WRITE
    mov     rdi, STDERR
    lea     rsi, [rel err_n]
    mov     rdx, err_n_l
    syscall
    mov     rax, SYS_EXIT
    mov     edi, 1
    syscall

die_word:
    mov     rax, SYS_WRITE
    mov     rdi, STDERR
    lea     rsi, [rel err_word]
    mov     rdx, err_word_l
    syscall
    mov     rax, SYS_CLOSE
    mov     rdi, r14
    syscall
    mov     rax, SYS_EXIT
    mov     edi, 1
    syscall