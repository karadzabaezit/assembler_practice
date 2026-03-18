bits	64
;	res=( b*c ) + ( a / (d+e) ) - ( (d*d) / b*e )
section	.data
res:
	dd	0
a:
	dd	1000000
b:
	dd	1000000
c:
	dd	1000000
d:
	dw	5
e:
	dw	5
section	.text
global	_start
_start:
	movsx	rdi, dword [b]
	movsx	rax, dword [c]
	imul	rax, rdi
	jo	err
	mov	rsi, rax

	movsx	rax, dword [a]
	movsx	rdi, word [d]
	movsx	rcx, word [e]
	add	rdi, rcx
	jo	err
	jz	err
	cqo
	idiv	rdi
	add	rsi, rax
	jo	err

	movsx	rax, word [d]
	imul	rax, rax
	movsx	rdi, dword [b]
	imul	rdi, rcx
	jo	err
	test	rdi, rdi
	jz	err
	cqo
	idiv	rdi

	sub	rsi, rax
	jo	err

	mov	[res], rsi

	mov     rax, 60
	mov     rdi, 0
	syscall
err:
	mov	rax, 60
	mov	rdi, 1
	syscall
