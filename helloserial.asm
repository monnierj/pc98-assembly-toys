[bits 16]
[org 0xF000]
[cpu 8086]

SERIAL_DATA_PORT: equ 0x30
SERIAL_CMD_PORT: equ 0x32

_main:
	push ax
	push ds
	mov ax, 0xA000
	mov ds, ax

	; Perform a full reset of the UART, as explained in the datasheet
	xor al, al
	mov cx, 3

_resetloop:
	out SERIAL_CMD_PORT, al
	call wait_some
	loop _resetloop

	; Do an internal reset
	mov al, 0x40
	out SERIAL_CMD_PORT, al
	call wait_some

	; We're finally in the MODE state. Set up asynchronous mode.
	mov al, 0x4F	; 1 stop bit, no parity, 8 bits of data, baud rate factor x64
	out SERIAL_CMD_PORT, al
	call wait_some

	; And reset the possible errors flags, while enabling the transmitter
	mov al, 0x11
	out SERIAL_CMD_PORT, al
	call wait_some

	; Put the message in the "source index" register
	mov si, msg

	; Load the message character count into CX.
 	mov cx, end-msg

_charloop:
	; Read the UART status register. If bit 0 (TXEMPTY) is not set,
	; re-read the status.
	in al, SERIAL_CMD_PORT
	and al, 0x01
	jz _charloop

 	lodsb	; load ds:si into al
	out SERIAL_DATA_PORT, al
	; Character is sent. Perform the same steps for the next one.
	loop _charloop

	; Restore the important registers, and return to the BASIC interpreter
	pop ds
	pop ax
	retf 2

wait_some:
	push cx

	mov cx, 0x4000
_wait_some_loop:
	nop
	loop _wait_some_loop

	pop cx
	ret

msg: db "Hello, serial port world!",13,10
end:
