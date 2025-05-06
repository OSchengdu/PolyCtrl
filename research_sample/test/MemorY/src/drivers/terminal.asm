BITS 32

global terminal_initialize
global terminal_putchar
global terminal_puts

section .data
vga_buffer equ 0xB8000  ; VGA 文本模式缓冲区地址
cursor_x dd 0           ; 光标 X 坐标
cursor_y dd 0           ; 光标 Y 坐标

section .text
terminal_initialize:
    ; 初始化终端
    mov dword [cursor_x], 0
    mov dword [cursor_y], 0
    ret

terminal_putchar:
    ; 显示一个字符
    mov edi, vga_buffer
    mov eax, [cursor_y]
    mov ebx, 80
    mul ebx
    add eax, [cursor_x]
    shl eax, 1
    add edi, eax
    mov [edi], al  ; 显示字符
    inc dword [cursor_x]
    cmp dword [cursor_x], 80
    jl .done
    call terminal_newline
.done:
    ret

terminal_puts:
    ; 显示一个字符串
    mov esi, [esp + 4]  ; 获取字符串地址
.loop:
    lodsb
    cmp al, 0
    je .done
    call terminal_putchar
    jmp .loop
.done:
    ret

terminal_newline:
    ; 换行
    mov dword [cursor_x], 0
    inc dword [cursor_y]
    cmp dword [cursor_y], 25
    jl .done
    call terminal_scroll
.done:
    ret

terminal_scroll:
	ret
	
section .data
init_msg db "Terminal initialized", 0	
