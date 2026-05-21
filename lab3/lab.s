%define SYS_READ        0
%define SYS_WRITE       1
%define SYS_OPEN        2
%define SYS_CLOSE       3
%define SYS_EXIT        60
%define STDOUT          1
%define STDERR          2
%define BUFFER_SIZE     4096
%define WORD_MAX_LEN    4095

section .data
    msg_usage       db "Usage: ./lab3 <input_file> <N>", 10
    msg_usage_len   equ $ - msg_usage
    msg_open_err    db "Error: cannot open input file", 10
    msg_open_len    equ $ - msg_open_err
    msg_word_err    db "Error: word exceeds 4095 characters", 10
    msg_word_len    equ $ - msg_word_err
    msg_n_err       db "Error: N must be a non-negative integer", 10
    msg_n_len       equ $ - msg_n_err
    char_space      db " "
    char_newline    db 10

section .bss
    read_buffer     resb BUFFER_SIZE
    word_buffer     resb BUFFER_SIZE
    rotate_buffer   resb BUFFER_SIZE

section .text
    global _start

_start:
    mov     rax, [rsp]
    cmp     rax, 3
    jne     exit_bad_usage

    mov     rcx, [rsp + 8]
    mov     rsi, [rsp + 16]
    mov     rdx, [rsp + 24]

    mov     rdi, rdx
    call    parse_uint
    cmp     rax, -1
    je      exit_bad_n
    mov     r15, rax

    mov     rax, SYS_OPEN
    mov     rdi, rsi
    xor     esi, esi
    xor     edx, edx
    syscall
    cmp     rax, 0
    jl      exit_bad_open
    mov     r14, rax

    xor     rbx, rbx
    xor     r12, r12
    xor     r13, r13

read_next_chunk:
    mov     rax, SYS_READ
    mov     rdi, r14
    lea     rsi, [rel read_buffer]
    mov     rdx, BUFFER_SIZE
    syscall
    cmp     rax, 0
    jl      read_next_chunk
    je      handle_eof
    mov     rbp, rax
    xor     r9, r9

process_chars:
    cmp     r9, rbp
    jge     read_next_chunk
    movzx   eax, byte [read_buffer + r9]
    inc     r9
    cmp     al, 10
    je      handle_newline_char
    cmp     al, 32
    je      handle_separator
    cmp     al, 9
    je      handle_separator

store_char:
    cmp     rbx, WORD_MAX_LEN
    jge     exit_word_too_long
    mov     [word_buffer + rbx], al
    inc     rbx
    jmp     process_chars

handle_separator:
    call    flush_word
    jmp     process_chars

handle_newline_char:
    call    flush_word
    call    write_newline
    jmp     process_chars

handle_eof:
    call    flush_word
    cmp     r12, 0
    je      close_and_exit
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    lea     rsi, [rel char_newline]
    mov     rdx, 1
    syscall

close_and_exit:
    mov     rax, SYS_CLOSE
    mov     rdi, r14
    syscall
    mov     rax, SYS_EXIT
    xor     edi, edi
    syscall

flush_word:
    cmp     rbx, 0
    je      flush_word_done
    cmp     r12, 0
    je      flush_word_no_space
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    lea     rsi, [rel char_space]
    mov     rdx, 1
    syscall
flush_word_no_space:
    mov     rdi, rbx
    call    write_rotated_word
    inc     r12
    xor     rbx, rbx
flush_word_done:
    ret

write_newline:
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    lea     rsi, [rel char_newline]
    mov     rdx, 1
    syscall
    xor     r12, r12
    inc     r13
    ret

write_rotated_word:
    mov     r10, rdi
    cmp     r10, 0
    je      write_rotated_done

    mov     rax, r15
    xor     edx, edx
    div     r10
    mov     r11, rdx

    cmp     r11, 0
    je      write_no_rotation

    lea     rsi, [rel word_buffer]
    add     rsi, r10
    sub     rsi, r11
    lea     rdi, [rel rotate_buffer]
    mov     rcx, r11
    rep     movsb

    lea     rsi, [rel word_buffer]
    lea     rdi, [rel rotate_buffer]
    add     rdi, r11
    mov     rcx, r10
    sub     rcx, r11
    rep     movsb

    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    lea     rsi, [rel rotate_buffer]
    mov     rdx, r10
    syscall
    jmp     write_rotated_done

write_no_rotation:
    mov     rax, SYS_WRITE
    mov     rdi, STDOUT
    lea     rsi, [rel word_buffer]
    mov     rdx, r10
    syscall

write_rotated_done:
    ret

parse_uint:
    xor     rax, rax
    xor     rcx, rcx
parse_uint_loop:
    movzx   edx, byte [rdi + rcx]
    cmp     dl, 0
    je      parse_uint_check
    cmp     dl, '0'
    jl      parse_uint_error
    cmp     dl, '9'
    jg      parse_uint_error
    imul    rax, rax, 10
    sub     edx, '0'
    add     rax, rdx
    inc     rcx
    jmp     parse_uint_loop
parse_uint_check:
    cmp     rcx, 0
    je      parse_uint_error
    ret
parse_uint_error:
    mov     rax, -1
    ret

exit_bad_usage:
    mov     rax, SYS_WRITE
    mov     rdi, STDERR
    lea     rsi, [rel msg_usage]
    mov     rdx, msg_usage_len
    syscall
    mov     rax, SYS_EXIT
    mov     edi, 1
    syscall

exit_bad_open:
    mov     rax, SYS_WRITE
    mov     rdi, STDERR
    lea     rsi, [rel msg_open_err]
    mov     rdx, msg_open_len
    syscall
    mov     rax, SYS_EXIT
    mov     edi, 1
    syscall

exit_bad_n:
    mov     rax, SYS_WRITE
    mov     rdi, STDERR
    lea     rsi, [rel msg_n_err]
    mov     rdx, msg_n_len
    syscall
    mov     rax, SYS_EXIT
    mov     edi, 1
    syscall

exit_word_too_long:
    mov     rax, SYS_WRITE
    mov     rdi, STDERR
    lea     rsi, [rel msg_word_err]
    mov     rdx, msg_word_len
    syscall
    mov     rax, SYS_CLOSE
    mov     rdi, r14
    syscall
    mov     rax, SYS_EXIT
    mov     edi, 1
    syscall