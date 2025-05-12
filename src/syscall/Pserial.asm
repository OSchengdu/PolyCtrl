; 串口初始化
serial_init:
    mov ax, [os_boot_arch]
    bt ax, 0
    jnc .serial_init_error
    or qword [os_SysConfEn], 1 << 2
.serial_init_error:
    ret

; 串口发送数据
serial_send:
    push rdx
    push rax
    call .wait_for_transmit_empty
    pop rax
    mov dx, COM_PORT_DATA
    out dx, al
    pop rdx
    ret

; 等待发送缓冲区为空
.wait_for_transmit_empty:
    mov dx, COM_PORT_LINE_STATUS
.in_loop:
    in al, dx
    and al, 0x20
    cmp al, 0
    je .in_loop
    ret

; 串口接收数据
serial_recv:
    push rdx
    mov dx, COM_PORT_LINE_STATUS
    in al, dx
    and al, 0x01
    cmp al, 0
    je .serial_recv_nochar
    mov dx, COM_PORT_DATA
    in al, dx
    cmp al, 0x0D
    je .serial_recv_enter
    cmp al, 0x7F
    je .serial_recv_backspace
    jmp .serial_recv_done

.serial_recv_nochar:
    xor al, al
    jmp .serial_recv_cleanup

.serial_recv_enter:
    mov al, 0x1C
    jmp .serial_recv_done

.serial_recv_backspace:
    mov al, 0x0E
    jmp .serial_recv_done

.serial_recv_done:
.serial_recv_cleanup:
    pop rdx
    ret

; 串口端口常量定义
COM_BASE			equ 0x3F8
COM_PORT_DATA			equ COM_BASE + 0
COM_PORT_INTERRUPT_ENABLE	equ COM_BASE + 1
COM_PORT_FIFO_CONTROL		equ COM_BASE + 2
COM_PORT_LINE_CONTROL		equ COM_BASE + 3
COM_PORT_MODEM_CONTROL		equ COM_BASE + 4
COM_PORT_LINE_STATUS		equ COM_BASE + 5
COM_PORT_MODEM_STATUS		equ COM_BASE + 6
COM_PORT_SCRATCH_REGISTER	equ COM_BASE + 7

; 波特率常量定义
BAUD_115200			equ 1
BAUD_57600			equ 2
BAUD_9600			equ 12
BAUD_300			equ 384

