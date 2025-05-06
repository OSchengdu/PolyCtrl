[BITS 32]

global _start
_start:
    ; 内核入口点
    ; 打印欢迎消息
    mov esi, welcome_msg
    call print_string

    ; 进入主循环
.main_loop:
    hlt
    jmp .main_loop

print_string:
    ; 打印字符串
    mov ah, 0x0E
.print_char:
    lodsb
    cmp al, 0
    je .done
    out 0x3F8, al  ; 通过串口输出
    jmp .print_char
.done:
    ret

; 数据段
welcome_msg db "Welcome to NASM_K!", 0
