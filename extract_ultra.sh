#!/bin/bash

# 增强版函数和类方法提取工具
# 功能：递归查找指定目录下的 .asm, .nasm 和 .py 文件，提取函数名和类方法

# 用法说明
usage() {
    echo "用法: $0 [选项] [目录]"
    echo "选项:"
    echo "  -h, --help      显示帮助信息"
    echo "  -v, --verbose   显示详细输出"
    echo "  -o FILE         将结果输出到文件"
    echo "  --no-color      禁用彩色输出"
    echo "  --only-names    仅显示名称，不显示文件路径"
    echo ""
    echo "示例:"
    echo "  $0 ~/kernel_dev                  # 扫描指定目录"
    echo "  $0 -o functions.txt ~/projects   # 将结果保存到文件"
    exit 0
}

# 初始化变量
VERBOSE=0
OUTPUT_FILE=""
NO_COLOR=0
ONLY_NAMES=0
SEARCH_DIR="."

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -v|--verbose) VERBOSE=1 ;;
        -o) OUTPUT_FILE="$2"; shift ;;
        --no-color) NO_COLOR=1 ;;
        --only-names) ONLY_NAMES=1 ;;
        *) SEARCH_DIR="$1" ;;
    esac
    shift
done

# 彩色输出设置
if [[ $NO_COLOR -eq 0 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# 检查目录是否存在
if [[ ! -d "$SEARCH_DIR" ]]; then
    echo -e "${RED}错误: 目录 '$SEARCH_DIR' 不存在${NC}" >&2
    exit 1
fi

# 显示扫描信息
echo -e "${GREEN}正在扫描目录: ${YELLOW}$(realpath "$SEARCH_DIR")${NC}"
if [[ -n "$OUTPUT_FILE" ]]; then
    echo -e "${BLUE}结果将保存到: ${YELLOW}$OUTPUT_FILE${NC}"
    > "$OUTPUT_FILE" # 清空或创建输出文件
fi

# 提取汇编文件中的函数
extract_asm_functions() {
    local file="$1"
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${BLUE}处理汇编文件: ${YELLOW}$file${NC}" >&2
    fi
    
    local funcs
    funcs=$(grep -E '^[[:space:]]*[[:alnum:]_]+[[:space:]]*:' "$file" | 
            sed -E 's/^[[:space:]]*([[:alnum:]_]+)[[:space:]]*:.*/\1/' | 
            sort | uniq)
    
    if [[ -z "$funcs" ]]; then
        return
    fi
    
    if [[ $ONLY_NAMES -eq 1 ]]; then
        echo "$funcs"
    else
        echo -e "\n${GREEN}文件: ${YELLOW}$file${NC}"
        echo -e "${GREEN}函数列表:${NC}"
        echo "$funcs" | while read -r func; do
            echo -e "  - ${BLUE}$func${NC}"
        done
    fi
}

# 提取Python文件中的函数和类方法
extract_python_functions() {
    local file="$1"
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${BLUE}处理Python文件: ${YELLOW}$file${NC}" >&2
    fi
    
    # 提取函数和类方法
    local items
    items=$(awk '
        /^[ \t]*(async[ \t]+)?def[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            sub(/^[ \t]*/, ""); 
            sub(/\(.*$/, ""); 
            sub(/^async[ \t]+/, ""); 
            sub(/^def[ \t]+/, ""); 
            print "function:" $0
        }
        /^[ \t]*class[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            sub(/^[ \t]*/, ""); 
            sub(/\(.*$/, ""); 
            sub(/^class[ \t]+/, ""); 
            print "class:" $0
        }
        /^[ \t]+(async[ \t]+)?def[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ && in_class {
            sub(/^[ \t]*/, ""); 
            sub(/\(.*$/, ""); 
            sub(/^async[ \t]+/, ""); 
            sub(/^def[ \t]+/, ""); 
            print "method:" class_name "." $0
        }
        ' "$file" | sort | uniq)
    
    if [[ -z "$items" ]]; then
        return
    fi
    
    if [[ $ONLY_NAMES -eq 1 ]]; then
        echo "$items"
    else
        echo -e "\n${GREEN}文件: ${YELLOW}$file${NC}"
        echo -e "${GREEN}函数/类/方法列表:${NC}"
        echo "$items" | while read -r item; do
            type=${item%%:*}
            name=${item#*:}
            case "$type" in
                "function") echo -e "  - ${BLUE}函数: $name${NC}" ;;
                "class") echo -e "  - ${GREEN}类: $name${NC}" ;;
                "method") echo -e "    - ${YELLOW}方法: $name${NC}" ;;
            esac
        done
    fi
}

# 处理输出函数
process_output() {
    if [[ -n "$OUTPUT_FILE" ]]; then
        tee -a "$OUTPUT_FILE"
    else
        cat
    fi
}

# 主扫描函数
scan_directory() {
    local dir="$1"
    
    # 查找并处理汇编文件
    find "$dir" -type f \( -name "*.asm" -o -name "*.nasm" \) | while read -r file; do
        extract_asm_functions "$file"
    done | process_output
    
    # 查找并处理Python文件
    find "$dir" -type f -name "*.py" | while read -r file; do
        extract_python_functions "$file"
    done | process_output
}

# 执行扫描
scan_directory "$SEARCH_DIR"

echo -e "${GREEN}\n扫描完成!${NC}"
