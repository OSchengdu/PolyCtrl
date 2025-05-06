BITS 32

global init_keyboard
global keyboard_handler

section .data
key_buffer times 128 db 0  ; 键盘输入缓冲区
key_buffer_index dd 0      ; 缓冲区索引

section .text
init_keyboard:
    ; 初始化键盘
    ret

keyboard_handler:
    ; 键盘中断处理程序
    in al, 0x60  ; 读取键盘扫描码
    cmp al, 0x1C ; 检查是否是回车键
    je .handle_enter
    ; 将扫描码转换为 ASCII 字符
    call scancode_to_ascii
    ; 将字符存储到缓冲区
    mov edi, key_buffer
    add edi, [key_buffer_index]
    mov [edi], al
    inc dword [key_buffer_index]
    ret

.handle_enter:
    ; 处理回车键
    mov byte [key_buffer + edi], 0  ; 添加字符串结束符
    mov dword [key_buffer_index], 0 ; 重置缓冲区索引
    ; 调用命令解析函数
    call parse_command
    ret

scancode_to_ascii:
    ; 将扫描码转换为 ASCII 字符
    ret

parse_command:
    ; 解析命令
    ret
