;; only usage is switch to 64 mode

switch_64BITS:
	;; long mode page
	;; PAE
	;; EFER register
	;; jp to 64BITS segement
	ret
