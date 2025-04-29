#!/bin/bash
# shared_lib.sh - 构建yamjson动态库版本

# 导入公共函数和变量
source "$(dirname "$0")/common.sh"

# 函数: 构建动态库版本
build_shared_lib() {
    local debug=$1
    local lib_name="libyamjson.so"
    local build_type="发布版"
    local build_flags="-O2"
    local yaml_lib="yaml"

    if [ "$debug" = "debug" ]; then
        lib_name="libyamjson-debug.so"
        build_type="调试版"
        build_flags="-g -D_DEBUG"
        yaml_lib="yaml-debug"
    fi

    log_info "正在构建${build_type}动态库 ${lib_name}..."

    # 确保依赖的yaml-cpp动态库存在
    ensure_yaml_shared_lib $debug
    if [ $? -ne 0 ]; then
        return 1
    fi

    # 复制yaml-cpp的头文件和库文件到dist目录
    log_info "复制yaml-cpp依赖文件..."
    cp "$YAML_LIB_HEADER" "$DIST_DIR/include/"

    if [ "$debug" = "debug" ]; then
        cp "$YAML_SHARED_DEBUG_LIB" "$DIST_DIR/lib/"
    else
        cp "$YAML_SHARED_LIB" "$DIST_DIR/lib/"
    fi

    # 复制yamjson的头文件到dist目录，并修改引用
    log_info "处理头文件..."
    # 创建一个临时文件来存储修改后的头文件
    local temp_header="$DIST_DIR/include/yamjson.h.tmp"

    # 复制头文件，但修改include语句使其引用正确的依赖
    echo "// yamjson头文件 - 动态库版本" > "$temp_header"
    echo "// 生成于 $(date)" >> "$temp_header"
    echo "#pragma once" >> "$temp_header"
    echo "" >> "$temp_header"
    echo "#include <string>" >> "$temp_header"
    echo "#include <iostream>" >> "$temp_header"
    echo "#include <memory>" >> "$temp_header"
    echo "#include \"json.hpp\"" >> "$temp_header"
    echo "#include \"yaml.hpp\"" >> "$temp_header"
    echo "" >> "$temp_header"

    # 添加原始头文件内容（跳过pragma once和include部分）
    cat "$HEADER" | grep -v "#pragma once" | grep -v "#include" >> "$temp_header"

    # 替换原始文件
    mv "$temp_header" "$DIST_DIR/include/yamjson.h"

    # 复制json.hpp到dist目录
    cp "$JSON_LIB" "$DIST_DIR/include/"

    # 编译创建动态库
    log_info "编译动态库..."
    g++ -std=c++11 $build_flags -I"$HEADER_DIR" -I"$EXT_DIR" -I"$YAML_MODULE/include" -fPIC -shared "$SOURCE" -o "$DIST_DIR/lib/$lib_name" -L"$YAML_MODULE/lib" -l$yaml_lib

    log_success "${build_type}动态库已生成：$DIST_DIR/lib/$lib_name"

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

    # 检查是否为调试版本
    if [[ "$1" == "debug" ]]; then
        build_shared_lib debug
    else
        build_shared_lib
    fi

    exit $?
fi