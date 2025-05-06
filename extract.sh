#!/bin/bash

# 递归查找当前目录下所有 .asm 或 .nasm 文件，并提取函数名
find_functions() {
    local dir="$1"
    # 支持 .asm 和 .nasm 文件
    find "$dir" -type f \( -name "*.asm" -o -name "*.nasm" \) | while read -r file; do
        echo -e "\n文件: $file"
        echo "函数列表:"
        # 提取函数名（格式为 "函数名:"）
        grep -E '^[[:space:]]*[[:alnum:]_]+[[:space:]]*:' "$file" | sed -E 's/^[[:space:]]*([[:alnum:]_]+)[[:space:]]*:.*/\1/' | sort | uniq | while read -r func; do
            echo "  - $func"
        done
    done
}

# 从当前目录开始查找
echo "正在扫描目录: $(pwd)"
find_functions "."
