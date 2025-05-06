[BITS 16]
[ORG 0x7C00]

start:
    ; 初始化段寄存器
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; 打印引导消息
    mov si, boot_msg
    call print_string

    ; 加载内核到内存
    ; 假设内核位于磁盘的第 2 个扇区
    mov ah, 0x02        ; BIOS 读取扇区功能
    mov al, 1           ; 读取 1 个扇区
    mov ch, 0           ; 柱面 0
    mov cl, 2           ; 从第 2 个扇区开始
    mov dh, 0           ; 磁头 0
    mov bx, 0x1000      ; 加载到内存地址 0x1000
    int 0x13            ; 调用 BIOS 中断
    jc disk_error       ; 如果出错，跳转到错误处理

    ; 切换到保护模式
    cli                 ; 禁用中断
    lgdt [gdt_descriptor] ; 加载 GDT
    mov eax, cr0
    or eax, 0x1         ; 设置保护模式位
    mov cr0, eax
    jmp 0x08:protected_mode ; 跳转到保护模式代码

[BITS 32]
protected_mode:
    ; 初始化段寄存器
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; 跳转到内核入口
    jmp 0x1000

[BITS 16]
print_string:
    ; 打印字符串
    mov ah, 0x0E
.print_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .print_char
.done:
    ret

disk_error:
    ; 磁盘错误处理
    mov si, disk_error_msg
    call print_string
    jmp $

; 数据段
boot_msg db "Booting OS...", 0
disk_error_msg db "Disk read error!", 0

; GDT 定义
gdt_start:
    dd 0x00000000  ; 空描述符
    dd 0x00000000
    dd 0x0000FFFF  ; 代码段描述符
    dd 0x00CF9A00
    dd 0x0000FFFF  ; 数据段描述符
    dd 0x00CF9200
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

times 510-($-$$) db 0   ; 填充剩余空间
dw 0xAA55               ; 引导扇区结束标志
