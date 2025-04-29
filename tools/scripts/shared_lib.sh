#!/bin/bash
# shared_lib.sh - 构建yamjson动态库版本

# 导入公共函数和变量
source "$(dirname "$0")/common.sh"

# 函数: 生成动态库版本
generate_shared_lib() {
    local debug=$1
    local lib_name="libyamjson.so"
    local compiler_flags="-O3 -fPIC"
    local dist_lib_dir="$DIST_DIR/lib"
    local dist_include_dir="$DIST_DIR/include"
    local yaml_lib="$LIB_DIR/libyaml.so"

    if [ "$debug" = "debug" ]; then
        lib_name="libyamjson-debug.so"
        compiler_flags="-g -O0 -DDEBUG -fPIC"
        yaml_lib="$LIB_DIR/libyaml-debug.so"
        log_info "正在生成调试版动态库 ${lib_name}..."
    else
        log_info "正在生成动态库 ${lib_name}..."
    fi

    # 首先确保依赖的yaml-cpp动态库存在
    ensure_yaml_shared_lib $debug
    if [ $? -ne 0 ]; then
        return 1
    fi

    # 创建临时构建目录
    local build_dir="$DIST_DIR/temp"
    mkdir -p "$build_dir"

    # 编译源文件为共享对象
    log_info "编译源文件..."
    g++ -std=c++11 $compiler_flags -I"$HEADER_DIR" -I"$EXT_DIR" -shared -o "$dist_lib_dir/$lib_name" "$SOURCE" $yaml_lib

    # 复制头文件到发布目录
    log_info "复制头文件..."
    cp "$HEADER" "$dist_include_dir/"
    cp "$JSON_LIB" "$dist_include_dir/"
    cp "$EXT_DIR/yaml.hpp" "$dist_include_dir/" 2>/dev/null || cp "$YAML_LIB_HEADER" "$dist_include_dir/"

    # 链接到主仓库lib目录
    ln -sf "$dist_lib_dir/$lib_name" "$LIB_DIR/$lib_name"
    log_success "已链接 $lib_name 到 lib 目录"

    # 清理临时文件
    rm -rf "$build_dir"

    log_success "动态库版本已生成：$dist_lib_dir/$lib_name"

    # 创建测试脚本
    if [ "$debug" = "debug" ]; then
        create_test_script "shared-debug"
    else
        create_test_script "shared"
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

    # 生成动态库
    generate_shared_lib $debug
    exit $?
fi