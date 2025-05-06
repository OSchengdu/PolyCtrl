BITS 16
ORG 0x7C00

;; under real mode
kernel_start:
	;;  initialization part
	cli
	xor ax, ax
	mox ds, ax
	mov es, ax

	;; load kernel to memory
	mov ah, 0x02
	mov al, 1		;the number of block will be read
	mov c, 0
	mov cl, 2
	mov dh, 0
	mov bx, 0x1000
	int 0x13		;MODIFIABLE: call BIIOS interrupt, if need load more block, then MODIFY the param
	jc disk_error       	;if errors occupied, jump to disk_error
	;; protect mode
	jmp 0x1000		;relative jump

times 510-($-$$) db 0		;fillup the rest space
dw 0xAA55			;end of MBR
