; 初始化MemHW
init_memhw:
    mov rsi, bus_table
    sub rsi, 8  ; 合并了原有的sub rsi, 16和add rsi, 8操作

; 检查MemHW设备
init_memhw_check_loop:
    add rsi, 16
    mov ax, [rsi]
    cmp ax, 0xFFFF
    je init_memhw_check_bus
    cmp ax, 0x0108
    je init_memhw
    jmp init_memhw_check_loop

; 检查其他总线设备
init_memhw_check_bus_loop:
    add rsi, 16
    mov ax, [rsi]
    cmp ax, 0xFFFF
    je init_memhw_done
    cmp ax, 0x0101
    je init_memhw_ata
    cmp ax, 0x0106
    je init_memhw_ahci
    cmp ax, 0x0100
    je init_memhw_virtio_blk
    jmp init_memhw_check_bus_loop

; 初始化MemHW设备
init_memhw:
    jmp init_device_common

; 初始化AHCI设备
init_memhw_ahci:
    jmp init_device_common

; 初始化Virtio块设备
init_memhw_virtio_blk:
    jmp init_device_common

; 初始化ATA设备
init_memhw_ata:
    jmp init_device_common

; 通用设备初始化部分
init_device_common:
    sub rsi, 8
    mov edx, [rsi]
    call [rax + init_func_table] ; 根据设备类型调用对应的初始化函数
    jmp init_memhw_done

; 初始化完成
init_memhw_done:
    mov ebx, 4
    call os_debug_block
    ret

; 初始化函数表
init_func_table:
    dd memhw_init
    dd ahci_init
    dd virtio_blk_init
    dd ata_init

