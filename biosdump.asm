[bits 16]
[org 0xF000]
[cpu 8086]

UART_DATA_PORT: equ 0x30
UART_CMD_PORT: equ 0x32

; PC-98 BIOS size, in kB.
BIOS_SIZE: equ 96
; How many 128 bytes blocks should be transferred
BLOCK_COUNT: equ (BIOS_SIZE * 1024) / 128

; ASCII constants for Xmodem implementation
SOH: equ 1
EOT: equ 4
ACK: equ 6
NAK: equ 21

main:
	push ax
	push ds

	; Perform a full reset of the UART, as explained in the datasheet
	xor al, al

	out UART_CMD_PORT, al	; Write three times 0x00 to the UART command port
	call wait_some
	out UART_CMD_PORT, al
	call wait_some
	out UART_CMD_PORT, al
	call wait_some

	; Do an internal reset
	mov al, 0x40
	out UART_CMD_PORT, al
	call wait_some

	; We're finally in the MODE state. Set up asynchronous mode.
	mov al, 0x4F	; 1 stop bit, no parity, 8 bits of data, baud rate factor x64
	out UART_CMD_PORT, al
	call wait_some

	; And reset the possible errors flags, while enabling the receiver and transmitter
	mov al, 0x15
	out UART_CMD_PORT, al
	call wait_some

	; Set our data segment to the start of the BIOS area
	mov ax, 0xE800
	mov ds, ax
	xor si, si

	; BX contains the current block number, zero-referenced.
	; We'll be using BL+1 as the current XMODEM block number.
	xor bx, bx

	; We're set. Wait for the NAK byte.

_nak_sync:
	call uart_read
	cmp al, NAK
	jnz _nak_sync

	; We recieved our request for a frame.
	; Send the Xmodem initial SOH byte
_frame_start:
	mov al, SOH
	call uart_write

	; Send the packet number and its 1's complement
	mov al, bl
	inc al
	call uart_write

	not al
	call uart_write

	; Send the 128 bytes of the frame
	xor dx, dx
	mov cx, 128

_data_loop:
	lodsb
	add dl, al	; Compute the checksum while we're at it.
	call uart_write
	loop _data_loop

	mov al, dl	; Send the checksum
	call uart_write

	; Wait for either ACK or NAK to come.
	call uart_read

	cmp al, NAK
	jz _frame_start

	; We've reached the end of a data block. If SI went back to 0, update DS
	; so we're pointing to the next 64kB of data
	cmp si, 0
	jnz _next_frame

	mov ax, ds
	add ax, 0x1000
	mov ds, ax

_next_frame:

	; We seem to have recieved an ACK byte. Increment the block counter
	inc bx
	cmp bx, BLOCK_COUNT
	jnz _frame_start	; If we have some blocks left, continue.

	; Else, we're done. End the transfer.
	mov al, EOT
	call uart_write

	; Read and discard what we recieved
	call uart_read

	; Send the final EOT. The receiver will consider transfer as done.
	mov al, EOT
	call uart_write


	pop ds
	pop ax
	retf 2

uart_read:
	; Wait for a byte to be recieved by the UART, and return it.
	; Input:
	; None.
	; Output:
	; AL=byte read from UART

	; Check whether RxRDY is set
	in al, UART_CMD_PORT
	and al, 0x02
	jz uart_read

	in al, UART_DATA_PORT
	ret

uart_write:
	; Writes a byte to the UART.
	; Input:
	; AL=byte to write.
	; Output:
	; AL=left as-is
	push ax
_uw_wait:
	; Loop until TxEMPTY and TxRDY are set
	in al, UART_CMD_PORT
	and al, 0x04
	jz _uw_wait

	pop ax

	out UART_DATA_PORT, al
	ret

wait_some:
	push cx

	mov cx, 0x4000
_wait_some_loop:
	nop
	loop _wait_some_loop

	pop cx
	ret
