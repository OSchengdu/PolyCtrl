#!/bin/bash

# 用法说明
usage() {
    echo "用法: $0 [选项] [目录]"
    echo "选项:"
    echo "  -h, --help      显示帮助信息"
    echo "  -v, --verbose   显示详细输出"
    echo "  -o FILE         将结果输出到文件"
    echo "  --no-color      禁用彩色输出"
    echo "  --only-names    仅显示名称，不显示文件路径"
    echo "  --lang LANG     指定要提取的语言(c,cpp,asm,python,typescript,javascript,rust,all), 默认all"
    echo ""
    echo "示例:"
    echo "  $0 ~/kernel_dev                  # 扫描指定目录"
    echo "  $0 -o functions.txt ~/projects   # 将结果保存到文件"
    echo "  $0 --lang cpp ~/src             # 只提取C++代码"
    exit 0
}

# 初始化变量
VERBOSE=0
OUTPUT_FILE=""
NO_COLOR=0
ONLY_NAMES=0
SEARCH_DIR="."
LANGUAGES="all"

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -v|--verbose) VERBOSE=1 ;;
        -o) OUTPUT_FILE="$2"; shift ;;
        --no-color) NO_COLOR=1 ;;
        --only-names) ONLY_NAMES=1 ;;
        --lang) LANGUAGES="$2"; shift ;;
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
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    MAGENTA=''
    NC=''
fi

# 检查目录是否存在
if [[ ! -d "$SEARCH_DIR" ]]; then
    echo -e "${RED}错误: 目录 '$SEARCH_DIR' 不存在${NC}" >&2
    exit 1
fi

# 显示扫描信息
echo -e "${GREEN}正在扫描目录: ${YELLOW}$(realpath "$SEARCH_DIR")${NC}"
echo -e "${GREEN}扫描语言: ${YELLOW}$LANGUAGES${NC}"
if [[ -n "$OUTPUT_FILE" ]]; then
    echo -e "${BLUE}结果将保存到: ${YELLOW}$OUTPUT_FILE${NC}"
    > "$OUTPUT_FILE" # 清空或创建输出文件
fi

# 提取C/C++文件中的函数、宏和结构体
extract_c_functions() {
    local file="$1"
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${BLUE}处理C/C++文件: ${YELLOW}$file${NC}" >&2
    fi

    # 提取函数、宏、结构体、枚举、类等
    local items
    items=$(awk '
        /^[ \t]*#define[ \t]+[A-Za-z_][A-Za-z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/[ \t]*$/, "");
            split($0, parts, /[ \t]+/);
            print "macro:" parts[2]
        }
        /^[ \t]*(typedef[ \t]+)?(enum|struct|union)[ \t]+[A-Za-z_][A-Za-z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/[ \t]*$/, "");
            if ($1 == "typedef") {
                type = $2;
                name = $3;
            } else {
                type = $1;
                name = $2;
            }
            print type ":" name
        }
        /^[ \t]*class[ \t]+[A-Za-z_][A-Za-z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/[ \t]*$/, "");
            print "class:" $2
        }
        /^[ \t]*[A-Za-z_][A-Za-z0-9_]*[ \t]+\**[ \t]*[A-Za-z_][A-Za-z0-9_]*[ \t]*\(/ {
            sub(/^[ \t]*/, "");
            sub(/[ \t]*$/, "");
            if ($0 !~ /;/) {
                split($0, parts, /[ \t]*\([ \t]*/);
                split(parts[1], decl, /[ \t]+/);
                print "function:" decl[length(decl)]
            }
        }
        ' "$file" | sort | uniq)

    if [[ -z "$items" ]]; then
        return
    fi

    if [[ $ONLY_NAMES -eq 1 ]]; then
        echo "$items"
    else
        echo -e "\n${GREEN}文件: ${YELLOW}$file${NC}"
        echo -e "${GREEN}C/C++元素列表:${NC}"
        echo "$items" | while read -r item; do
            type=${item%%:*}
            name=${item#*:}
            case "$type" in
                "macro") echo -e "  - ${MAGENTA}宏: $name${NC}" ;;
                "struct") echo -e "  - ${CYAN}结构体: $name${NC}" ;;
                "enum") echo -e "  - ${CYAN}枚举: $name${NC}" ;;
                "union") echo -e "  - ${CYAN}联合体: $name${NC}" ;;
                "class") echo -e "  - ${GREEN}类: $name${NC}" ;;
                "function") echo -e "  - ${BLUE}函数: $name${NC}" ;;
                *) echo -e "  - $type: $name" ;;
            esac
        done
    fi
}

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

# 提取Python文件中的函数、类和模块
extract_python_functions() {
    local file="$1"
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${BLUE}处理Python文件: ${YELLOW}$file${NC}" >&2
    fi

    # 提取函数、类、方法和模块级变量
    local items
    items=$(awk '
        BEGIN { in_class = 0 }
        /^[ \t]*(async[ \t]+)?def[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/\(.*$/, "");
            sub(/^async[ \t]+/, "");
            sub(/^def[ \t]+/, "");
            if (in_class) {
                print "method:" class_name "." $0
            } else {
                print "function:" $0
            }
        }
        /^[ \t]*class[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/\(.*$/, "");
            sub(/^class[ \t]+/, "");
            class_name = $0;
            in_class = 1;
            print "class:" $0
        }
        /^[ \t]*[a-zA-Z_][a-zA-Z0-9_]*[ \t]*=[ \t]*[^ ]+/ {
            if (!in_class) {
                sub(/^[ \t]*/, "");
                sub(/[ \t]*=.*$/, "");
                print "variable:" $0
            }
        }
        /^[ \t]*$/ { in_class = 0 }
        ' "$file" | sort | uniq)

    if [[ -z "$items" ]]; then
        return
    fi

    if [[ $ONLY_NAMES -eq 1 ]]; then
        echo "$items"
    else
        echo -e "\n${GREEN}文件: ${YELLOW}$file${NC}"
        echo -e "${GREEN}Python元素列表:${NC}"
        echo "$items" | while read -r item; do
            type=${item%%:*}
            name=${item#*:}
            case "$type" in
                "function") echo -e "  - ${BLUE}函数: $name${NC}" ;;
                "class") echo -e "  - ${GREEN}类: $name${NC}" ;;
                "method") echo -e "    - ${YELLOW}方法: $name${NC}" ;;
                "variable") echo -e "  - ${CYAN}变量: $name${NC}" ;;
            esac
        done
    fi
}

# 提取TypeScript/JavaScript文件中的函数、类和变量
extract_js_functions() {
    local file="$1"
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${BLUE}处理TypeScript/JavaScript文件: ${YELLOW}$file${NC}" >&2
    fi

    # 提取函数、类、方法和变量
    local items
    items=$(awk '
        BEGIN { in_class = 0 }
        /^[ \t]*(export[ \t]+)?(async[ \t]+)?function[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/\(.*$/, "");
            sub(/^export[ \t]+/, "");
            sub(/^async[ \t]+/, "");
            sub(/^function[ \t]+/, "");
            print "function:" $0
        }
        /^[ \t]*(export[ \t]+)?(const|let|var)[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*=[ \t]*function[ \t]*\(/ {
            sub(/^[ \t]*/, "");
            sub(/[ \t]*=.*$/, "");
            sub(/^export[ \t]+/, "");
            sub(/^(const|let|var)[ \t]+/, "");
            print "function:" $0
        }
        /^[ \t]*(export[ \t]+)?(const|let|var)[ \t]+[a-zA-Z_][a-zA-Z0-9_]*[ \t]*=[ \t]*\(/ {
            sub(/^[ \t]*/, "");
            sub(/[ \t]*=.*$/, "");
            sub(/^export[ \t]+/, "");
            sub(/^(const|let|var)[ \t]+/, "");
            print "function:" $0
        }
        /^[ \t]*(export[ \t]+)?class[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/\{.*$/, "");
            sub(/^export[ \t]+/, "");
            sub(/^class[ \t]+/, "");
            class_name = $0;
            in_class = 1;
            print "class:" $0
        }
        /^[ \t]*(public|private|protected)?[ \t]*(static[ \t]+)?(async[ \t]+)?[a-zA-Z_][a-zA-Z0-9_]*[ \t]*\(/ {
            if (in_class) {
                sub(/^[ \t]*/, "");
                sub(/\(.*$/, "");
                sub(/^(public|private|protected)[ \t]+/, "");
                sub(/^static[ \t]+/, "");
                sub(/^async[ \t]+/, "");
                print "method:" class_name "." $0
            }
        }
        /^[ \t]*(export[ \t]+)?(const|let|var)[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            if (!in_class) {
                sub(/^[ \t]*/, "");
                sub(/[ \t]*=.*$/, "");
                sub(/^export[ \t]+/, "");
                sub(/^(const|let|var)[ \t]+/, "");
                print "variable:" $0
            }
        }
        /^[ \t]*\}[ \t]*$/ { in_class = 0 }
        ' "$file" | sort | uniq)

    if [[ -z "$items" ]]; then
        return
    fi

    if [[ $ONLY_NAMES -eq 1 ]]; then
        echo "$items"
    else
        echo -e "\n${GREEN}文件: ${YELLOW}$file${NC}"
        echo -e "${GREEN}TypeScript/JavaScript元素列表:${NC}"
        echo "$items" | while read -r item; do
            type=${item%%:*}
            name=${item#*:}
            case "$type" in
                "function") echo -e "  - ${BLUE}函数: $name${NC}" ;;
                "class") echo -e "  - ${GREEN}类: $name${NC}" ;;
                "method") echo -e "    - ${YELLOW}方法: $name${NC}" ;;
                "variable") echo -e "  - ${CYAN}变量: $name${NC}" ;;
            esac
        done
    fi
}

# 提取Rust文件中的函数、结构体和模块
extract_rust_functions() {
    local file="$1"
    if [[ $VERBOSE -eq 1 ]]; then
        echo -e "${BLUE}处理Rust文件: ${YELLOW}$file${NC}" >&2
    fi

    # 提取函数、结构体、枚举、trait和模块
    local items
    items=$(awk '
        /^[ \t]*(pub[ \t]+)?fn[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/\(.*$/, "");
            sub(/^pub[ \t]+/, "");
            sub(/^fn[ \t]+/, "");
            print "function:" $0
        }
        /^[ \t]*(pub[ \t]+)?struct[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/\{.*$/, "");
            sub(/^pub[ \t]+/, "");
            sub(/^struct[ \t]+/, "");
            print "struct:" $0
        }
        /^[ \t]*(pub[ \t]+)?enum[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/\{.*$/, "");
            sub(/^pub[ \t]+/, "");
            sub(/^enum[ \t]+/, "");
            print "enum:" $0
        }
        /^[ \t]*(pub[ \t]+)?trait[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/\{.*$/, "");
            sub(/^pub[ \t]+/, "");
            sub(/^trait[ \t]+/, "");
            print "trait:" $0
        }
        /^[ \t]*(pub[ \t]+)?mod[ \t]+[a-zA-Z_][a-zA-Z0-9_]*/ {
            sub(/^[ \t]*/, "");
            sub(/\{.*$/, "");
            sub(/^pub[ \t]+/, "");
            sub(/^mod[ \t]+/, "");
            print "module:" $0
        }
        ' "$file" | sort | uniq)

    if [[ -z "$items" ]]; then
        return
    fi

    if [[ $ONLY_NAMES -eq 1 ]]; then
        echo "$items"
    else
        echo -e "\n${GREEN}文件: ${YELLOW}$file${NC}"
        echo -e "${GREEN}Rust元素列表:${NC}"
        echo "$items" | while read -r item; do
            type=${item%%:*}
            name=${item#*:}
            case "$type" in
                "function") echo -e "  - ${BLUE}函数: $name${NC}" ;;
                "struct") echo -e "  - ${GREEN}结构体: $name${NC}" ;;
                "enum") echo -e "  - ${CYAN}枚举: $name${NC}" ;;
                "trait") echo -e "  - ${MAGENTA}Trait: $name${NC}" ;;
                "module") echo -e "  - ${YELLOW}模块: $name${NC}" ;;
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

    # 根据语言选择处理哪些文件
    if [[ "$LANGUAGES" == "all" || "$LANGUAGES" == *c* ]]; then
        # 查找并处理C文件
        find "$dir" -type f \( -name "*.c" -o -name "*.h" \) | while read -r file; do
            extract_c_functions "$file"
        done | process_output
    fi

    if [[ "$LANGUAGES" == "all" || "$LANGUAGES" == *cpp* ]]; then
        # 查找并处理C++文件
        find "$dir" -type f \( -name "*.cpp" -o -name "*.hpp" -o -name "*.cc" -o -name "*.cxx" -o -name "*.hxx" \) | while read -r file; do
            extract_c_functions "$file"
        done | process_output
    fi

    if [[ "$LANGUAGES" == "all" || "$LANGUAGES" == *asm* ]]; then
        # 查找并处理汇编文件
        find "$dir" -type f \( -name "*.asm" -o -name "*.s" -o -name "*.S" -o -name "*.nasm" \) | while read -r file; do
            extract_asm_functions "$file"
        done | process_output
    fi

    if [[ "$LANGUAGES" == "all" || "$LANGUAGES" == *python* ]]; then
        # 查找并处理Python文件
        find "$dir" -type f -name "*.py" | while read -r file; do
            extract_python_functions "$file"
        done | process_output
    fi

    if [[ "$LANGUAGES" == "all" || "$LANGUAGES" == *typescript* || "$LANGUAGES" == *javascript* ]]; then
        # 查找并处理TypeScript/JavaScript文件
        find "$dir" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" \) | while read -r file; do
            extract_js_functions "$file"
        done | process_output
    fi

    if [[ "$LANGUAGES" == "all" || "$LANGUAGES" == *rust* ]]; then
        # 查找并处理Rust文件
        find "$dir" -type f -name "*.rs" | while read -r file; do
            extract_rust_functions "$file"
        done | process_output
    fi
}

# 执行扫描
scan_directory "$SEARCH_DIR"

echo -e "${GREEN}\n扫描完成!${NC}"
