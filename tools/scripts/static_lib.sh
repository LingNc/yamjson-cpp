#!/bin/bash
# static_lib.sh - 构建yamjson静态库版本

# 导入公共函数和变量
source "$(dirname "$0")/common.sh"
# 直接导入合并头文件模块
source "$(dirname "$0")/merged_lib_header.sh"

# 函数: 生成静态库版本
generate_static_lib() {
    local debug=$1
    local lib_name="libyamjson.a"
    local compiler_flags="-O3"
    local dist_lib_dir="$DIST_DIR/lib"
    local dist_include_dir="$DIST_DIR/include"

    if [ "$debug" = "debug" ]; then
        lib_name="libyamjson-debug.a"
        compiler_flags="-g -O0 -DDEBUG"
        log_info "正在生成调试版静态库 ${lib_name}..."
    else
        log_info "正在生成静态库 ${lib_name}..."
    fi

    # 首先确保依赖的yaml-cpp静态库存在
    ensure_yaml_static_lib $debug
    if [ $? -ne 0 ]; then
        return 1
    fi

    # 创建临时构建目录
    local build_dir="$DIST_DIR/temp"
    mkdir -p "$build_dir"

    # 生成合并的头文件
    log_info "生成合并头文件..."
    # 直接调用函数而不是通过子Shell
    generate_merged_lib_header
    if [ $? -ne 0 ]; then
        log_error "生成合并头文件失败!"
        return 1
    fi

    # 编译源文件
    log_info "编译源文件..."
    g++ -std=c++11 $compiler_flags -I"$HEADER_DIR" -I"$EXT_DIR" -c "$SOURCE" -o "$build_dir/yamjson.o"

    # 创建静态库
    log_info "创建静态库..."
    ar rcs "$dist_lib_dir/$lib_name" "$build_dir/yamjson.o"

    # 复制头文件到发布目录 (只保留合并的头文件和原始的yamjson.h作为备份)
    log_info "复制头文件..."
    cp "$HEADER" "$dist_include_dir/yamjson_original.h"  # 保留原始头文件作为备份

    # 链接到主仓库lib目录
    ln -sf "$dist_lib_dir/$lib_name" "$LIB_DIR/$lib_name"
    log_success "已链接 $lib_name 到 lib 目录"

    # 清理临时文件
    rm -rf "$build_dir"

    log_success "静态库版本已生成：$dist_lib_dir/$lib_name"
    log_success "合并头文件已生成：$dist_include_dir/yamjson_lib.h"

    # 创建测试脚本
    if [ "$debug" = "debug" ]; then
        create_test_script "static-debug"
    else
        create_test_script "static"
    fi

    return 0
}

# 如果直接运行此脚本，则执行构建
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 检查依赖
    check_dependencies
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # 获取参数，确定是否生成调试版本
    debug=""
    if [ "$1" = "debug" ]; then
        debug="debug"
    fi

    # 生成静态库
    generate_static_lib $debug
    exit $?
fi