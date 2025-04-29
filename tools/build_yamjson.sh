#!/bin/bash
# build_yamjson.sh - 主构建脚本，用于生成yamjson库的各种版本

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# 确保脚本可执行
chmod +x "$SCRIPTS_DIR"/*.sh

# 导入公共函数和变量
source "$SCRIPTS_DIR/common.sh"

# 显示帮助信息
show_help() {
    echo -e "${BLUE}YamJSON 构建工具${NC}"
    echo "============================"
    echo -e "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help         显示此帮助信息"
    echo "  -s, --single       生成单头文件版本"
    echo "  -t, --static       生成静态库版本"
    echo "  -td, --static-debug 生成调试版静态库"
    echo "  -d, --shared       生成动态库版本"
    echo "  -dd, --shared-debug 生成调试版动态库"
    echo "  -a, --all          生成所有版本"
    echo ""
    echo "示例:"
    echo "  $0                 # 显示交互式菜单"
    echo "  $0 --single        # 生成单头文件版本"
    echo "  $0 --all           # 生成所有版本"
    echo ""
}

# 交互式菜单
show_menu() {
    echo -e "${BLUE}请选择要构建的版本:${NC}"
    echo "1) 单头文件版本 (默认)"
    echo "2) 静态库版本 (发布版)"
    echo "3) 静态库版本 (调试版)"
    echo "4) 动态库版本 (发布版)"
    echo "5) 动态库版本 (调试版)"
    echo "6) 所有版本"
    echo "0) 退出"

    read -p "请选择 [1-6] (默认 1): " choice

    choice=${choice:-1}

    case $choice in
        0)
            echo "已取消操作"
            exit 0
            ;;
        1)
            "$SCRIPTS_DIR/single_header.sh"
            "$SCRIPTS_DIR/readme.sh"
            ;;
        2)
            "$SCRIPTS_DIR/static_lib.sh"
            "$SCRIPTS_DIR/readme.sh"
            ;;
        3)
            "$SCRIPTS_DIR/static_lib.sh" debug
            "$SCRIPTS_DIR/readme.sh"
            ;;
        4)
            "$SCRIPTS_DIR/shared_lib.sh"
            "$SCRIPTS_DIR/readme.sh"
            ;;
        5)
            "$SCRIPTS_DIR/shared_lib.sh" debug
            "$SCRIPTS_DIR/readme.sh"
            ;;
        6)
            "$SCRIPTS_DIR/single_header.sh"
            "$SCRIPTS_DIR/static_lib.sh"
            "$SCRIPTS_DIR/static_lib.sh" debug
            "$SCRIPTS_DIR/shared_lib.sh"
            "$SCRIPTS_DIR/shared_lib.sh" debug
            "$SCRIPTS_DIR/readme.sh"
            ;;
        *)
            echo -e "${RED}无效选择!${NC}"
            exit 1
            ;;
    esac
}

# 主函数
main() {
    # 检查依赖
    check_dependencies
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # 如果没有参数，显示交互式菜单
    if [ $# -eq 0 ]; then
        show_menu
        exit 0
    fi

    # 处理命令行参数
    while [ $# -gt 0 ]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--single)
                "$SCRIPTS_DIR/single_header.sh"
                ;;
            -t|--static)
                "$SCRIPTS_DIR/static_lib.sh"
                ;;
            -td|--static-debug)
                "$SCRIPTS_DIR/static_lib.sh" debug
                ;;
            -d|--shared)
                "$SCRIPTS_DIR/shared_lib.sh"
                ;;
            -dd|--shared-debug)
                "$SCRIPTS_DIR/shared_lib.sh" debug
                ;;
            -a|--all)
                "$SCRIPTS_DIR/single_header.sh"
                "$SCRIPTS_DIR/static_lib.sh"
                "$SCRIPTS_DIR/static_lib.sh" debug
                "$SCRIPTS_DIR/shared_lib.sh"
                "$SCRIPTS_DIR/shared_lib.sh" debug
                ;;
            *)
                echo -e "${RED}无效参数: $1${NC}"
                show_help
                exit 1
                ;;
        esac
        shift
    done

    # 生成README文件
    "$SCRIPTS_DIR/readme.sh"
}

# 执行主函数
main "$@"