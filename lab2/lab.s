global _start

section .data

matrix:
    db 3, 3
    db 5, 2, 8
    db 10, 9, 3
    db 4, 6, 7

rows db 0
cols db 0

mins  times 255 db 0
order times 255 db 0

new_matrix times 255 db 0

section .text

_start:
    mov rsi, matrix
    mov r12, rsi

    mov al, [rsi]
    mov [rows], al

    mov al, [rsi+1]
    mov [cols], al

    add r12, 2            ; r12 начало данных матрицы

    xor rbx, rbx          ; j = 0

find_cols:
    mov al, [cols]
    cmp bl, al
    jge sort_phase

    mov byte [mins + rbx], 127

    xor rdi, rdi          ; i = 0

row_loop:
    mov al, [rows]
    cmp dil, al
    jge next_col

    movzx rax, dil
    movzx rcx, byte [cols]
    imul rax, rcx
    add rax, rbx

    mov dl, [r12 + rax]

    mov al, [mins + rbx]
    cmp dl, al
    jae skip_min

    mov [mins + rbx], dl

skip_min:
    inc rdi
    jmp row_loop

next_col:
    mov [order + rbx], bl
    inc rbx
    jmp find_cols



sort_phase:
    mov rbx, 1

outer:
    mov al, [cols]
    cmp bl, al
    jge rearrange

    mov al, [mins + rbx]      ; key
    mov dl, [order + rbx]

    xor rsi, rsi              ; left = 0
    mov rdi, rbx              ; right = i

binary_search:
    cmp rsi, rdi
    jge found_pos

    mov rcx, rsi
    add rcx, rdi
    shr rcx, 1

    mov r8b, [mins + rcx]
    cmp r8b, al
    jle move_right

    mov rdi, rcx
    jmp binary_search

move_right:
    lea rsi, [rcx + 1]
    jmp binary_search

found_pos:
    mov rcx, rbx

shift_loop:
    cmp rcx, rsi
    jle insert

    mov r8b, [mins + rcx - 1]
    mov [mins + rcx], r8b

    mov r9b, [order + rcx - 1]
    mov [order + rcx], r9b

    dec rcx
    jmp shift_loop

insert:
    mov [mins + rsi], al
    mov [order + rsi], dl

    inc rbx
    jmp outer



rearrange:
    xor rdi, rdi      ; i = 0

row_copy:
    mov al, [rows]
    cmp dil, al
    jge write_back

    xor rbx, rbx      ; j = 0

col_copy:
    mov al, [cols]
    cmp bl, al
    jge next_row

    ; old[i][order[j]]
    movzx rax, dil
    movzx rcx, byte [cols]
    imul rax, rcx

    movzx rdx, byte [order + rbx]
    add rax, rdx

    mov dl, [r12 + rax]

    ; new[i][j]
    movzx r8, dil
    movzx rcx, byte [cols]
    imul r8, rcx
    add r8, rbx

    mov [new_matrix + r8], dl

    inc rbx
    jmp col_copy

next_row:
    inc rdi
    jmp row_copy



write_back:
    xor rdi, rdi

wb_row:
    mov al, [rows]
    cmp dil, al
    jge exit

    xor rbx, rbx

wb_col:
    mov al, [cols]
    cmp bl, al
    jge next_wb_row

    movzx rax, dil
    movzx rcx, byte [cols]
    imul rax, rcx
    add rax, rbx

    mov dl, [new_matrix + rax]
    mov [r12 + rax], dl

    inc rbx
    jmp wb_col

next_wb_row:
    inc rdi
    jmp wb_row

exit:
    mov rax, 60
    xor rdi, rdi
    syscall