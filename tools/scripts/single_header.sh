#!/bin/bash
# single_header.sh - 构建yamjson单头文件版本

# 导入公共函数和变量
source "$(dirname "$0")/common.sh"

# 函数: 生成ASCII艺术字标题
generate_ascii_header() {
    local version=${YAMJSON_VERSION:-1.0.0}
    local date_str=$(date "+%Y-%m-%d")
    local system_info=$(uname -a)

    cat << "EOF"
/*
 *  oooooo   oooo       .o.       ooo        ooooo    oooo  .oooooo..o   .oooooo.   ooooo      ooo
 *   `888.   .8'       .888.      `88.       .888'    `888 d8P'    `Y8  d8P'  `Y8b  `888b.     `8'
 *    `888. .8'       .8"888.      888b     d'888      888 Y88bo.      888      888  8 `88b.    8
 *     `888.8'       .8' `888.     8 Y88. .P  888      888  `"Y8888o.  888      888  8   `88b.  8
 *      `888'       .88ooo8888.    8  `888'   888      888      `"Y88b 888      888  8     `88b.8
 *       888       .8'     `888.   8    Y     888      888 oo     .d8P `88b    d88'  8       `888
 *      o888o     o88o     o8888o o8o        o888o .o. 88P 8""88888P'   `Y8bood8P'  o8o        `8
 *                                                 `Y888P
 *
 */
EOF

    echo "/*"
    echo " * YAMJSON - YAML to JSON converter for C++"
    echo " * Version: $version"
    echo " * GitHub: https://github.com/LingNc/yamjson"
    echo " * License: MIT"
    echo " * Built on: $date_str"
    echo " * 构建系统: $system_info"
    echo " * 作者: LingNc"
    echo " */"
}

# 函数: 生成完全自包含的单头文件版本
generate_single_header() {
    log_info "正在生成单头文件版本 ${SINGLE_HEADER}..."

    # 首先确保依赖的yaml-cpp单头文件存在
    ensure_yaml_single_header
    if [ $? -ne 0 ]; then
        return 1
    fi

    local output_file="$DIST_DIR/include/$SINGLE_HEADER"

    # 创建单头文件，首先添加ASCII艺术标题
    generate_ascii_header > "$output_file"
    echo "" >> "$output_file"
    echo "#pragma once" >> "$output_file"
    echo "" >> "$output_file"

    # 添加使用说明
    echo "// 用法说明:" >> "$output_file"
    echo "// 在所有需要使用 yamjson 的文件中:" >> "$output_file"
    echo "// #include \"yamjson.hpp\"" >> "$output_file"
    echo "// " >> "$output_file"
    echo "// 在且仅在一个源文件中添加以下代码:" >> "$output_file"
    echo "// #define YAMJSON_IMPLEMENTATION" >> "$output_file"
    echo "// #include \"yamjson.hpp\"" >> "$output_file"
    echo "" >> "$output_file"

    # 添加标准库依赖
    echo "#include <string>" >> "$output_file"
    echo "#include <iostream>" >> "$output_file"
    echo "#include <stdexcept>" >> "$output_file"
    echo "#include <memory>" >> "$output_file"
    echo "#include <vector>" >> "$output_file"
    echo "#include <map>" >> "$output_file"
    echo "" >> "$output_file"

    # 内联包含JSON库（直接嵌入内容）
    log_info "内联包含JSON库..."
    echo "// ========== JSON库内联开始 ==========" >> "$output_file"
    echo "// JSON for Modern C++ (v3.11.2)" >> "$output_file"
    echo "// https://github.com/nlohmann/json" >> "$output_file"
    echo "" >> "$output_file"
    cat "$JSON_LIB" >> "$output_file"
    echo "" >> "$output_file"
    echo "// ========== JSON库内联结束 ==========" >> "$output_file"
    echo "" >> "$output_file"

    # 内联包含YAML-CPP库（直接嵌入内容）
    log_info "内联包含YAML-CPP库..."
    echo "// ========== YAML-CPP库内联开始 ==========" >> "$output_file"
    echo "// YAML-CPP单头文件版本" >> "$output_file"
    echo "// 原始项目: https://github.com/jbeder/yaml-cpp" >> "$output_file"
    echo "" >> "$output_file"
    cat "$YAML_SINGLE_HEADER" >> "$output_file"
    echo "" >> "$output_file"
    echo "// ========== YAML-CPP库内联结束 ==========" >> "$output_file"
    echo "" >> "$output_file"

    # YAML-CPP实现部分宏变量控制
    echo "// 确保YAML库的实现只在一次包含" >> "$output_file"
    echo "#ifdef YAMJSON_IMPLEMENTATION" >> "$output_file"
    echo "#ifndef YAML_CPP_IMPLEMENTATION" >> "$output_file"
    echo "#define YAML_CPP_IMPLEMENTATION" >> "$output_file"
    echo "#endif" >> "$output_file"
    echo "#endif" >> "$output_file"
    echo "" >> "$output_file"

    # 添加yamjson头文件内容（不包含原有的include语句）
    echo "// ========== YAMJSON头文件部分开始 ==========" >> "$output_file"
    log_info "添加yamjson头文件内容..."
    cat "$HEADER" | grep -v "#pragma once" | grep -v "#include" >> "$output_file"
    echo "// ========== YAMJSON头文件部分结束 ==========" >> "$output_file"
    echo "" >> "$output_file"

    # 添加实现部分，被宏保护
    echo "// ========== YAMJSON实现部分开始 ==========" >> "$output_file"
    echo "#ifdef YAMJSON_IMPLEMENTATION" >> "$output_file"
    echo "#ifndef YAMJSON_IMPLEMENTATION_INCLUDED" >> "$output_file"
    echo "#define YAMJSON_IMPLEMENTATION_INCLUDED" >> "$output_file"
    echo "" >> "$output_file"

    # 添加源文件内容（忽略include语句）
    log_info "添加yamjson实现内容..."
    cat "$SOURCE" | grep -v "#include" >> "$output_file"

    # 添加实现宏保护结束
    echo "" >> "$output_file"
    echo "#endif // YAMJSON_IMPLEMENTATION_INCLUDED" >> "$output_file"
    echo "#endif // YAMJSON_IMPLEMENTATION" >> "$output_file"
    echo "// ========== YAMJSON实现部分结束 ==========" >> "$output_file"

    log_success "单头文件版本已生成：$output_file"

    # 创建测试脚本
    create_test_script "single"

    return 0
}

# 如果直接运行此脚本，则执行构建
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 检查依赖
    check_dependencies
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # 生成单头文件
    generate_single_header
    exit $?
fi