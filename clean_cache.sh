#!/bin/bash

# ArchLinux 内存清理脚本
# 功能：提供多种内存清理选项，帮助释放系统内存

# 检查是否以root用户运行
if [ "$(id -u)" -ne 0 ]; then
    echo "此脚本需要root权限，请使用sudo运行"
    exit 1
fi

# 显示当前内存使用情况
show_memory() {
    echo -e "\n当前内存使用情况:"
    free -h
    echo -e "\n内存缓存情况:"
    grep -E 'MemTotal|MemFree|Buffers|Cached|SReclaimable|SUnreclaim' /proc/meminfo
}

# 清理页面缓存
clean_pagecache() {
    echo -e "\n正在清理页面缓存..."
    sync; echo 1 > /proc/sys/vm/drop_caches
    echo "页面缓存已清理"
}

# 清理dentries和inodes
clean_dentries_inodes() {
    echo -e "\n正在清理dentries和inodes..."
    sync; echo 2 > /proc/sys/vm/drop_caches
    echo "dentries和inodes已清理"
}

# 清理页面缓存、dentries和inodes
clean_all() {
    echo -e "\n正在清理页面缓存、dentries和inodes..."
    sync; echo 3 > /proc/sys/vm/drop_caches
    echo "所有缓存已清理"
}

# 清理swap空间
clean_swap() {
    echo -e "\n正在清理swap空间..."
    swapoff -a && swapon -a
    echo "swap空间已清理"
}

# 清理未使用的slab内存
clean_slab() {
    echo -e "\n正在清理slab内存..."
    sync; echo 2 > /proc/sys/vm/drop_caches
    sync; echo 3 > /proc/sys/vm/drop_caches
    echo "slab内存已清理"
}

# 主菜单
main_menu() {
    clear
    echo "===================================="
    echo " ArchLinux 内存清理工具"
    echo "===================================="
    echo "1. 显示当前内存使用情况"
    echo "2. 清理页面缓存"
    echo "3. 清理dentries和inodes"
    echo "4. 清理所有缓存(页面缓存+dentries+inodes)"
    echo "5. 清理swap空间"
    echo "6. 清理slab内存"
    echo "7. 执行全面清理(所有上述选项)"
    echo "8. 退出"
    echo "===================================="
    
    read -p "请选择操作 [1-8]: " choice
    
    case $choice in
        1) show_memory ;;
        2) clean_pagecache ;;
        3) clean_dentries_inodes ;;
        4) clean_all ;;
        5) clean_swap ;;
        6) clean_slab ;;
        7) 
            clean_pagecache
            clean_dentries_inodes
            clean_swap
            clean_slab
            ;;
        8) exit 0 ;;
        *) echo "无效选项，请重新选择" ;;
    esac
    
    read -p "按回车键继续..."
    main_menu
}

# 显示初始内存状态
show_memory

# 启动主菜单
main_menu
