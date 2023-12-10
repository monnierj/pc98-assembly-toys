[bits 16]
[org 0xF000]
[cpu 8086]


CONSOLE_LINE_LENGTH: equ 160

main:
	push cs
	pop ds

	; Reset VRAM, white text, not secret mode, fill screen with blank spaces
	mov ah, 0x16
	mov dx, 0xE120
	int 0x18

	mov si, greeting_msg
	call puts

	mov si, disk_80_header
	call puts

	mov ah, 0x84
	mov al, 0x80
	int 0x1B

	call reg_dump

	mov si, lf_str
	call puts

	mov si, disk_00_header
	call puts

	mov ah, 0x84
	mov al, 0x00
	int 0x1B

	call reg_dump

	jmp $

reg_dump:
	; Dump AX, BX, CX, DX values
	push dx
	push cx
	push bx
	push ax

	mov si, reg_ax
	call puts
	pop ax
	call dump_word

	mov si, reg_bx
	call puts
	pop ax
	call dump_word

	mov si, reg_cx
	call puts
	pop ax
	call dump_word

	mov si, reg_dx
	call puts
	pop ax
	call dump_word

	ret

puts:
	; Writes a static message on-screen. Only supports US-ASCII strings.
	; DS:SI -> source address of a C string.
	push ax
	push dx
	push es

	; Set ES to the text VRAM segment
	mov ax, 0xA000
	mov es, ax

	mov di, [tvram_cur_char_ptr]

	xor ax, ax

_puts_charwrite:
	lodsb

	cmp al, 13	; Line Feed handler
	jz _puts_lf

	cmp al, 0	; NULL character handler
	jz _puts_end

	stosw	; We've got a normal ASCII character, just print it out.
	loop _puts_charwrite

_puts_lf:
	; Set "current line start pointer" to the start of the next line, and use that
	; new value as the current character position
	mov di, [tvram_cur_line_start_ptr]
	add di, CONSOLE_LINE_LENGTH
	mov [tvram_cur_line_start_ptr], di

	jmp _puts_charwrite

_puts_end:
	mov [tvram_cur_char_ptr], di

	; Update cursor position

	mov ah, 0x13
	mov dx, di
	inc dx
	int 0x18


	pop es
	pop dx
	pop ax
	ret

dump_word:
	mov [word_buffer], word ax

	push es
	push di
	push ax

	; Set ES to the Text VRAM
	mov ax, 0xA000
	mov es, ax

	; Restore previous cursor position
	mov di, [tvram_cur_char_ptr]

	; Prepare to dump the highest nibble of the most significant byte.
	mov al, [word_buffer+1]
	shr al, 1
	shr al, 1
	shr al, 1
	shr al, 1
	call dump_nibble

	; Lower nibble, most significant byte
	mov al, [word_buffer+1]
	and al, 0x0F
	call dump_nibble

	; Highest nibble, least significant byte
	mov al, [word_buffer]
	shr al, 1
	shr al, 1
	shr al, 1
	shr al, 1
	call dump_nibble

	; Lower nibble, least significant byte
	mov al, [word_buffer]
	and al, 0x0F
	call dump_nibble

	mov [tvram_cur_char_ptr], di

	pop ax
	pop di
	pop es
	ret

dump_nibble:
	add al, 0x30	; Add 32 to current AL value to find out which ASCII numeric character we have.

	cmp al, 0x39
	jng _dump_nibble_post_adjust

	; Current character exceeds 0x39: we had a value comprised between A and F.
	add al, 7

_dump_nibble_post_adjust:
	; Write current hexadecimal digit on screen. ES:DI are supposedly already set up
	stosb
	xor al, al
	stosb

	ret

; Messages
greeting_msg: db "Disk 80h sense test", 13, 0
disk_80_header: db "---- Disk 80h ----", 13, 0
disk_00_header: db "---- Disk 00h ----", 13, 0
lf_str: db 13, 0
reg_ax: db "AX: ", 0
reg_bx: db 13, "BX: ", 0
reg_cx: db 13, "CX: ", 0
reg_dx: db 13, "DX: ", 0

; Global variables
word_buffer: dw 0
tvram_cur_line_start_ptr: dw 0
tvram_cur_char_ptr: dw 0

