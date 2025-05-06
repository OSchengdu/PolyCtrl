align 16
db 'DEBUG: INIT'
align 16
	
%include "init/64mod.asm"
%include "init/bus.asm"
%include "init/storage.asm"
	
