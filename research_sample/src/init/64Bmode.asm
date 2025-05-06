;; ==========================
;; nasm_k
;; Copyright (C) 2008-2025 OSchengdu3 -- see LICENSE.TXT


;; only usage is switch to 64 mode
align 16
db 'DEBUG: INIT_64'
align 16


init_64BITS:
	mov rdi, 
	
switch_64BITS:
	;; long mode page
	;; PAE
	;; EFER register
	;; jp to 64BITS segement
	ret
