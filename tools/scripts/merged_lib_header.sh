#!/bin/bash
# merged_lib_header.sh - 为库版本创建合并头文件

# 导入公共函数和变量
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# 函数: 生成合并的库头文件
generate_merged_lib_header() {
    local output_dir="$DIST_DIR/include"
    local output_file="$output_dir/yamjson_lib.h"

    log_info "正在生成库版本合并头文件: $output_file"

    # 创建输出目录（如果不存在）
    mkdir -p "$output_dir"

    # 检查所需文件是否存在
    if [ ! -f "$JSON_LIB" ]; then
        log_error "找不到 JSON 库文件: $JSON_LIB"
        return 1
    fi

    if [ ! -f "$EXT_DIR/yaml.hpp" ] && [ ! -f "$YAML_LIB_HEADER" ]; then
        log_error "找不到 YAML 库头文件: $EXT_DIR/yaml.hpp 或 $YAML_LIB_HEADER"
        return 1
    fi

    if [ ! -f "$HEADER" ]; then
        log_error "找不到 YamJSON 头文件: $HEADER"
        return 1
    fi

    # 确定要使用的 YAML 头文件
    local yaml_header=""
    if [ -f "$EXT_DIR/yaml.hpp" ]; then
        yaml_header="$EXT_DIR/yaml.hpp"
    else
        yaml_header="$YAML_LIB_HEADER"
    fi

    # 创建合并的头文件
    cat << EOF > "$output_file"
/*
 * yamjson_lib.h - YamJSON 库合并头文件
 * 版本: ${YAMJSON_VERSION:-1.0.0}
 * 构建日期: $(date "+%Y-%m-%d %H:%M:%S")
 *
 * 这个文件是自动生成的，包含所有 YamJSON 库所需的头文件。
 * 在使用静态库或动态库版本时，只需包含此文件即可。
 */

#pragma once
#ifndef YAMJSON_LIB_H
#define YAMJSON_LIB_H

// ===== 包含 JSON 库 =====
EOF

    # 添加 json.hpp 内容
    log_info "添加 JSON 库内容..."
    cat "$JSON_LIB" >> "$output_file"

    echo -e "\n// ===== 包含 YAML 库 =====\n" >> "$output_file"

    # 添加 yaml.hpp 内容
    log_info "添加 YAML 库内容..."
    cat "$yaml_header" >> "$output_file"

    echo -e "\n// ===== 包含 YamJSON 库 =====\n" >> "$output_file"

    # 添加 yamjson.h 内容（排除已包含的部分）
    log_info "添加 YamJSON 库内容..."

    # 读取 yamjson.h，但排除对 json.hpp 和 yaml.hpp 的 include
    sed '/^\s*#include\s\+"json\.hpp"\s*$/d; /^\s*#include\s\+"yaml\.hpp"\s*$/d' "$HEADER" >> "$output_file"

    # 关闭头文件
    echo -e "\n#endif // YAMJSON_LIB_H" >> "$output_file"

    log_success "库版本合并头文件已创建: $output_file"

    # 返回生成的文件路径
    echo "$output_file"
    return 0
}

# 如果直接运行此脚本，则执行合并
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 检查依赖
    check_dependencies
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # 生成合并的库头文件
    generate_merged_lib_header
    exit $?
fi