#!/bin/bash
# common.sh - 共享的变量和函数 (主入口)

# 定义当前脚本目录
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# 导入拆分的模块
source "$CURRENT_DIR/logger.sh"
source "$CURRENT_DIR/paths.sh"
source "$CURRENT_DIR/yaml_deps.sh"
source "$CURRENT_DIR/testing.sh"
# 不要导入 merged_lib_header.sh，避免循环依赖

# 脚本版本号
export YAMJSON_SCRIPTS_VERSION="1.1.0"

# 如果直接运行此脚本，显示导入的模块
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "YamJSON脚本库 v${YAMJSON_SCRIPTS_VERSION}"
    log_info "已导入以下模块:"
    log_success "logger.sh - 日志输出相关函数"
    log_success "paths.sh - 路径和文件定义"
    log_success "yaml_deps.sh - YAML依赖管理相关函数"
    log_success "testing.sh - 测试脚本生成相关函数"
    log_success "merged_lib_header.sh - 合并头文件生成相关函数 (按需导入)"
fi