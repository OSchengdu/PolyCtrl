BITS 32

extern terminal_puts
global parse_command

section .data
command_buffer times 128 db 0  ; 命令缓冲区

section .text
parse_command:
    ; 解析命令
    mov esi, command_buffer
    ; 检查命令并执行
    ; 示例：实现 "help" 命令
    cmp byte [esi], 'h'
    jne .unknown_command
    cmp byte [esi + 1], 'e'
    jne .unknown_command
    cmp byte [esi + 2], 'l'
    jne .unknown_command
    cmp byte [esi + 3], 'p'
    jne .unknown_command
    ; 显示帮助信息
    mov esi, help_msg
    call terminal_puts
    ret

.unknown_command:
    ; 显示未知命令信息
    mov esi, unknown_msg
    call terminal_puts
    ret


	
	
section .data
help_msg db "Available commands: help", 0
unknown_msg db "Unknown command. Type 'help' for a list of commands.", 0
