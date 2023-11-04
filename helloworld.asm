[bits 16]
[org 0xF000]

_main:
	push ax
	push ds
	push es
	; Disable interrupts, since things seems to go pretty bad
	; with the changed segments
	cli
	mov ax, 0xA000
	mov es, ax
	mov ds, ax

	; Put the message in the "source index" register
	mov si, msg
	; Put the first character of the third line (each line of texts uses 160 bytes of
	; memory)
	mov di, 320

 	mov cx, end-msg

	xor ax, ax ; Clean up AX, since we're going to read 8 bits, but write 16 bits each time
 _strloop:
 	lodsb	; load ds:si into al
 	stosw	; write ax into es:di
 	loop _strloop

	; Re-enable interrupts, or we'll end with a locked machine.
	sti
	pop es
	pop ds
	pop ax
	retf 2

msg: db "Hello, world!"
end:
