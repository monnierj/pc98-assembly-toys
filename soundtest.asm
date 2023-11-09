[bits 16]
[org 0xF000]
[cpu 8086]

YM2203_STATUS_PORT: equ 0x188
YM2203_ADDRESS_PORT: equ 0x188
YM2203_DATA_PORT: equ 0x18A

; SSG Channel A counter, sets channel A square tone frequency using the
; following formula:
;            fMaster/2
; counter = -----------
;            16*fChannel
; where fMaster = 3993600Hz. We must divide it by 2, since the YM2203 is
; clocked to half the input frequency if chip select pin is low.
; Unsure about this, seen from YM2149 datasheet
CHANNEL_A_COUNTER: equ 0x11B	; 440Hz, according to the previous formula
; SSG Channel A volume. 0 is silent, F is full volume.
CHANNEL_A_VOLUME: equ 0x08

_main:
	push ax
	; Set address to the SSG /ENABLE register
	mov dx, YM2203_ADDRESS_PORT
	mov al, 0x07
	out dx, al
	call wait_for_ym2203_idle

	; Enable channel A
	mov dx, YM2203_DATA_PORT
	mov al, 0xFE
	out dx, al
	call wait_for_ym2203_idle

	; Set up channel A divider fine tone adjustment
	mov dx, YM2203_ADDRESS_PORT
	mov al, 0x00
	out dx, al
	call wait_for_ym2203_idle

	mov dx, YM2203_DATA_PORT
	mov al, (CHANNEL_A_COUNTER & 0xFF)
	out dx, al
	call wait_for_ym2203_idle

	; Set up channel A divider coarse tone adjustment
	mov dx, YM2203_ADDRESS_PORT
	mov al, 0x01
	out dx, al
	call wait_for_ym2203_idle

	mov dx, YM2203_DATA_PORT
	mov al, (CHANNEL_A_COUNTER >> 8)
	out dx, al
	call wait_for_ym2203_idle

	; Set up channel A volume
	mov dx, YM2203_ADDRESS_PORT
	mov al, 0x08
	out dx, al
	call wait_for_ym2203_idle

	mov dx, YM2203_DATA_PORT
	mov al, CHANNEL_A_VOLUME
	out dx, al

	; Return to the BASIC interpreter. Square tone is still being output.
	pop ax
	retf 2

wait_for_ym2203_idle:
	push dx

	mov dx, YM2203_STATUS_PORT
_idle_loop:
	in al, dx
	and al, 0x80
	jnz _idle_loop

	pop dx
	ret
