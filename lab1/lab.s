bits	64
;	res=( b*c ) + ( a / (d+e) ) - ( (d*d) / b*e )
section	.data
res:
	dd	0
a:
	dd	100
b:
	dd	-10
c:
	dd	4
d:
	dw	10
e:
	dw	5
section	.text
global	_start
_start:
	mov	edi, [b]
	mov	eax, [c]
	imul	eax, edi
	mov	esi, eax

	mov	eax, [a]
	movsx	edi, word[d]
	movsx	ecx, word[e]
	add	edi, ecx
	jz	err
	cdq
	idiv	edi
	add	esi, eax

	movsx	eax, word[d]
	imul	eax, eax
	mov	edi, [b]
	imul	edi, ecx
	test	edi, edi
	jz	err
	cdq
	idiv	edi

	sub	esi, eax

	mov	[res], esi

	mov     eax, 60
	mov     edi, 0
	syscall
err:
	mov	eax, 60
	mov	edi, 1
	syscall
