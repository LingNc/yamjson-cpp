#!/bin/bash
# yamjson 构建工具 - 用于生成各种版本的 yamjson 库

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # 无颜色

# 路径定义
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
HEADER_DIR="$ROOT_DIR/include"
SRC_DIR="$ROOT_DIR/src"
DIST_DIR="$ROOT_DIR/dist"
EXT_DIR="$ROOT_DIR/ext"
MODULE_DIR="$ROOT_DIR/module"
YAML_MODULE="$MODULE_DIR/yaml-cpp-builder"

# 文件定义
HEADER="$HEADER_DIR/yamjson.h"
SOURCE="$SRC_DIR/yamjson.cpp"
SINGLE_HEADER="yamjson.hpp"
JSON_LIB="$EXT_DIR/json.hpp"
YAML_SINGLE_HEADER="$YAML_MODULE/include/yaml-cpp.hpp"
YAML_LIB_HEADER="$YAML_MODULE/include/yaml.hpp"
YAML_STATIC_LIB="$YAML_MODULE/lib/libyaml.a"
YAML_STATIC_DEBUG_LIB="$YAML_MODULE/lib/libyaml-debug.a"
YAML_SHARED_LIB="$YAML_MODULE/lib/libyaml.so"
YAML_SHARED_DEBUG_LIB="$YAML_MODULE/lib/libyaml-debug.so"

# 创建必要的目录
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/include"
mkdir -p "$DIST_DIR/lib"

# 函数: 显示帮助信息
show_help() {
    echo -e "${BLUE}YamJSON 构建工具${NC}"
    echo "============================"
    echo -e "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help       显示此帮助信息"
    echo "  -s, --single     生成单头文件版本 (默认)"
    echo "  -t, --static     生成静态库版本"
    echo "  -td, --static-debug  生成调试版静态库"
    echo "  -d, --shared     生成动态库版本"
    echo "  -dd, --shared-debug  生成调试版动态库"
    echo "  -a, --all        生成所有版本"
    echo ""
    echo "示例:"
    echo "  $0               # 生成单头文件版本"
    echo "  $0 --static      # 生成静态库版本"
    echo "  $0 --all         # 生成所有版本"
    echo ""
}

# 函数: 检查依赖
check_dependencies() {
    echo -e "${BLUE}正在检查依赖...${NC}"

    # 检查 json.hpp
    if [ ! -f "$JSON_LIB" ]; then
        echo -e "${RED}错误: 找不到 json.hpp 文件!${NC}"
        echo -e "请下载 nlohmann/json 库放置到 $JSON_LIB 位置:"
        echo -e "${YELLOW}wget https://github.com/nlohmann/json/releases/download/v3.11.2/json.hpp -O $JSON_LIB${NC}"
        return 1
    else
        echo -e "${GREEN}✓ json.hpp 已找到${NC}"
    fi

    # 检查 yaml-cpp-builder 模块
    if [ ! -d "$YAML_MODULE" ]; then
        echo -e "${RED}错误: 找不到 yaml-cpp-builder 模块!${NC}"
        echo -e "请初始化并更新子模块:"
        echo -e "${YELLOW}git submodule init && git submodule update${NC}"
        return 1
    else
        echo -e "${GREEN}✓ yaml-cpp-builder 模块已找到${NC}"
    fi

    return 0
}

# 函数: 确保yaml-cpp单头文件存在
ensure_yaml_single_header() {
    if [ ! -f "$YAML_SINGLE_HEADER" ]; then
        echo -e "${YELLOW}警告: 找不到 yaml-cpp.hpp 单头文件!${NC}"
        read -p "是否构建 yaml-cpp 单头文件? (Y/n): " build_yaml
        build_yaml=${build_yaml:-Y}

        if [[ $build_yaml =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}正在构建 yaml-cpp 单头文件...${NC}"
            (cd "$YAML_MODULE" && make merged-header)

            if [ ! -f "$YAML_SINGLE_HEADER" ]; then
                echo -e "${RED}错误: yaml-cpp.hpp 构建失败!${NC}"
                return 1
            else
                echo -e "${GREEN}✓ yaml-cpp.hpp 已成功构建${NC}"
            fi
        else
            echo -e "${RED}错误: 需要 yaml-cpp.hpp 才能继续!${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ yaml-cpp.hpp 已找到${NC}"
    fi

    return 0
}

# 函数: 确保yaml-cpp静态库存在
ensure_yaml_static_lib() {
    local debug=$1
    local lib_path="$YAML_STATIC_LIB"
    local lib_name="libyaml.a"
    local build_cmd="make static-lib"

    if [ "$debug" = "debug" ]; then
        lib_path="$YAML_STATIC_DEBUG_LIB"
        lib_name="libyaml-debug.a"
        build_cmd="make static-lib-debug"
    fi

    if [ ! -f "$lib_path" ] || [ ! -f "$YAML_LIB_HEADER" ]; then
        echo -e "${YELLOW}警告: 找不到 yaml-cpp 静态库 ($lib_name) 或头文件!${NC}"
        read -p "是否构建 yaml-cpp 静态库? (Y/n): " build_yaml
        build_yaml=${build_yaml:-Y}

        if [[ $build_yaml =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}正在构建 yaml-cpp 静态库...${NC}"
            (cd "$YAML_MODULE" && $build_cmd)

            if [ ! -f "$lib_path" ] || [ ! -f "$YAML_LIB_HEADER" ]; then
                echo -e "${RED}错误: yaml-cpp 静态库构建失败!${NC}"
                return 1
            else
                echo -e "${GREEN}✓ yaml-cpp 静态库已成功构建${NC}"
            fi
        else
            echo -e "${RED}错误: 需要 yaml-cpp 静态库才能继续!${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ yaml-cpp 静态库 ($lib_name) 已找到${NC}"
    fi

    return 0
}

# 函数: 确保yaml-cpp动态库存在
ensure_yaml_shared_lib() {
    local debug=$1
    local lib_path="$YAML_SHARED_LIB"
    local lib_name="libyaml.so"
    local build_cmd="make shared-lib"

    if [ "$debug" = "debug" ]; then
        lib_path="$YAML_SHARED_DEBUG_LIB"
        lib_name="libyaml-debug.so"
        build_cmd="make shared-lib-debug"
    fi

    if [ ! -f "$lib_path" ] || [ ! -f "$YAML_LIB_HEADER" ]; then
        echo -e "${YELLOW}警告: 找不到 yaml-cpp 动态库 ($lib_name) 或头文件!${NC}"
        read -p "是否构建 yaml-cpp 动态库? (Y/n): " build_yaml
        build_yaml=${build_yaml:-Y}

        if [[ $build_yaml =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}正在构建 yaml-cpp 动态库...${NC}"
            (cd "$YAML_MODULE" && $build_cmd)

            if [ ! -f "$lib_path" ] || [ ! -f "$YAML_LIB_HEADER" ]; then
                echo -e "${RED}错误: yaml-cpp 动态库构建失败!${NC}"
                return 1
            else
                echo -e "${GREEN}✓ yaml-cpp 动态库已成功构建${NC}"
            fi
        else
            echo -e "${RED}错误: 需要 yaml-cpp 动态库才能继续!${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ yaml-cpp 动态库 ($lib_name) 已找到${NC}"
    fi

    return 0
}

# 函数: 创建测试脚本/示例
create_test_script() {
    local type=$1
    local script_file="$DIST_DIR/test_yamjson.sh"

    echo -e "${BLUE}创建测试脚本: ${script_file}...${NC}"

    echo "#!/bin/bash" > "$script_file"
    echo "# yamjson 测试脚本 - 简单测试生成的库是否正常工作" >> "$script_file"
    echo "" >> "$script_file"

    case $type in
        single)
            echo "echo \"测试单头文件版本...\"" >> "$script_file"
            echo "echo '#define YAMJSON_IMPLEMENTATION' > test.cpp" >> "$script_file"
            echo "echo '#include \"include/yamjson.hpp\"' >> test.cpp" >> "$script_file"
            echo "echo 'int main() {' >> test.cpp" >> "$script_file"
            echo "echo '    yamjson::YamJSON y;' >> test.cpp" >> "$script_file"
            echo "echo '    y.loadYaml(\"key: value\");' >> test.cpp" >> "$script_file"
            echo "echo '    std::cout << \"测试成功: \" << y.toJSON() << std::endl;' >> test.cpp" >> "$script_file"
            echo "echo '    return 0;' >> test.cpp" >> "$script_file"
            echo "echo '}' >> test.cpp" >> "$script_file"
            echo "g++ -std=c++11 test.cpp -o test_yamjson -I." >> "$script_file"
            echo "./test_yamjson" >> "$script_file"
            echo "rm test.cpp test_yamjson" >> "$script_file"
            ;;
        static)
            echo "echo \"测试静态库版本...\"" >> "$script_file"
            echo "echo '#include \"include/yamjson.h\"' > test.cpp" >> "$script_file"
            echo "echo 'int main() {' >> test.cpp" >> "$script_file"
            echo "echo '    yamjson::YamJSON y;' >> test.cpp" >> "$script_file"
            echo "echo '    y.loadYaml(\"key: value\");' >> test.cpp" >> "$script_file"
            echo "echo '    std::cout << \"测试成功: \" << y.toJSON() << std::endl;' >> test.cpp" >> "$script_file"
            echo "echo '    return 0;' >> test.cpp" >> "$script_file"
            echo "echo '}' >> test.cpp" >> "$script_file"
            echo "g++ -std=c++11 test.cpp -o test_yamjson -I. -Llib -lyamjson -lyaml" >> "$script_file"
            echo "LD_LIBRARY_PATH=./lib ./test_yamjson" >> "$script_file"
            echo "rm test.cpp test_yamjson" >> "$script_file"
            ;;
        static-debug)
            echo "echo \"测试调试版静态库...\"" >> "$script_file"
            echo "echo '#include \"include/yamjson.h\"' > test.cpp" >> "$script_file"
            echo "echo 'int main() {' >> test.cpp" >> "$script_file"
            echo "echo '    yamjson::YamJSON y;' >> test.cpp" >> "$script_file"
            echo "echo '    y.loadYaml(\"key: value\");' >> test.cpp" >> "$script_file"
            echo "echo '    std::cout << \"测试成功: \" << y.toJSON() << std::endl;' >> test.cpp" >> "$script_file"
            echo "echo '    return 0;' >> test.cpp" >> "$script_file"
            echo "echo '}' >> test.cpp" >> "$script_file"
            echo "g++ -std=c++11 -g test.cpp -o test_yamjson -I. -Llib -lyamjson-debug -lyaml-debug" >> "$script_file"
            echo "LD_LIBRARY_PATH=./lib ./test_yamjson" >> "$script_file"
            echo "rm test.cpp test_yamjson" >> "$script_file"
            ;;
        shared)
            echo "echo \"测试动态库版本...\"" >> "$script_file"
            echo "echo '#include \"include/yamjson.h\"' > test.cpp" >> "$script_file"
            echo "echo 'int main() {' >> test.cpp" >> "$script_file"
            echo "echo '    yamjson::YamJSON y;' >> test.cpp" >> "$script_file"
            echo "echo '    y.loadYaml(\"key: value\");' >> test.cpp" >> "$script_file"
            echo "echo '    std::cout << \"测试成功: \" << y.toJSON() << std::endl;' >> test.cpp" >> "$script_file"
            echo "echo '    return 0;' >> test.cpp" >> "$script_file"
            echo "echo '}' >> test.cpp" >> "$script_file"
            echo "g++ -std=c++11 test.cpp -o test_yamjson -I. -Llib -lyamjson -lyaml" >> "$script_file"
            echo "LD_LIBRARY_PATH=./lib ./test_yamjson" >> "$script_file"
            echo "rm test.cpp test_yamjson" >> "$script_file"
            ;;
        shared-debug)
            echo "echo \"测试调试版动态库...\"" >> "$script_file"
            echo "echo '#include \"include/yamjson.h\"' > test.cpp" >> "$script_file"
            echo "echo 'int main() {' >> test.cpp" >> "$script_file"
            echo "echo '    yamjson::YamJSON y;' >> test.cpp" >> "$script_file"
            echo "echo '    y.loadYaml(\"key: value\");' >> test.cpp" >> "$script_file"
            echo "echo '    std::cout << \"测试成功: \" << y.toJSON() << std::endl;' >> test.cpp" >> "$script_file"
            echo "echo '    return 0;' >> test.cpp" >> "$script_file"
            echo "echo '}' >> test.cpp" >> "$script_file"
            echo "g++ -std=c++11 -g test.cpp -o test_yamjson -I. -Llib -lyamjson-debug -lyaml-debug" >> "$script_file"
            echo "LD_LIBRARY_PATH=./lib ./test_yamjson" >> "$script_file"
            echo "rm test.cpp test_yamjson" >> "$script_file"
            ;;
    esac

    chmod +x "$script_file"
    echo -e "${GREEN}✓ 测试脚本已创建: $script_file${NC}"
}

# 函数: 生成单头文件版本
generate_single_header() {
    echo -e "${BLUE}正在生成单头文件版本 ${SINGLE_HEADER}...${NC}"

    # 首先确保依赖的yaml-cpp单头文件存在
    ensure_yaml_single_header
    if [ $? -ne 0 ]; then
        return 1
    fi

    # 创建单头文件
    echo "// yamjson single header - generated on $(date)" > "$DIST_DIR/include/$SINGLE_HEADER"
    echo "// https://github.com/LingNc/yamjson" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "// MIT License" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#pragma once" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "" >> "$DIST_DIR/include/$SINGLE_HEADER"

    # 添加使用说明
    echo "// 用法说明:" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "// 在所有需要使用 yamjson 的文件中:" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "// #include \"yamjson.hpp\"" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "// " >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "// 在且仅在一个源文件中添加以下代码:" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "// #define YAMJSON_IMPLEMENTATION" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "// #include \"yamjson.hpp\"" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "" >> "$DIST_DIR/include/$SINGLE_HEADER"

    # 添加头文件依赖
    echo "#include <string>" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#include <iostream>" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#include <stdexcept>" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#include <memory>" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "" >> "$DIST_DIR/include/$SINGLE_HEADER"

    # 添加json.hpp依赖
    echo "// JSON库依赖" >> "$DIST_DIR/include/$SINGLE_HEADER"
    cp "$JSON_LIB" "$DIST_DIR/include/"
    echo "#include \"json.hpp\"" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "" >> "$DIST_DIR/include/$SINGLE_HEADER"

    # 添加yaml-cpp.hpp依赖
    echo "// YAML库依赖 (stb风格)" >> "$DIST_DIR/include/$SINGLE_HEADER"
    cp "$YAML_SINGLE_HEADER" "$DIST_DIR/include/"
    echo "#ifdef YAMJSON_IMPLEMENTATION" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#define YAML_CPP_IMPLEMENTATION" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#endif" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#include \"yaml-cpp.hpp\"" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "" >> "$DIST_DIR/include/$SINGLE_HEADER"

    # 添加头文件内容（忽略 #pragma once 和 #include 语句）
    echo "// 头文件部分" >> "$DIST_DIR/include/$SINGLE_HEADER"
    cat "$HEADER" | grep -v "#pragma once" | grep -v "#include" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "" >> "$DIST_DIR/include/$SINGLE_HEADER"

    # 添加实现部分，被宏保护
    echo "// 实现部分" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#ifdef YAMJSON_IMPLEMENTATION" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#ifndef YAMJSON_IMPLEMENTATION_INCLUDED" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#define YAMJSON_IMPLEMENTATION_INCLUDED" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "" >> "$DIST_DIR/include/$SINGLE_HEADER"

    # 添加源文件内容（忽略 #include 语句）
    cat "$SOURCE" | grep -v "#include" >> "$DIST_DIR/include/$SINGLE_HEADER"

    # 添加实现宏保护结束
    echo "" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#endif // YAMJSON_IMPLEMENTATION_INCLUDED" >> "$DIST_DIR/include/$SINGLE_HEADER"
    echo "#endif // YAMJSON_IMPLEMENTATION" >> "$DIST_DIR/include/$SINGLE_HEADER"

    echo -e "${GREEN}✓ 单头文件版本已生成：$DIST_DIR/include/$SINGLE_HEADER${NC}"

    # 创建测试脚本
    create_test_script "single"

    return 0
}

# 函数: 构建静态库版本
build_static_lib() {
    local debug=$1
    local lib_name="libyamjson.a"
    local build_type="发布版"
    local build_flags="-O2"
    local yaml_lib="yaml"

    if [ "$debug" = "debug" ]; then
        lib_name="libyamjson-debug.a"
        build_type="调试版"
        build_flags="-g -D_DEBUG"
        yaml_lib="yaml-debug"
    fi

    echo -e "${BLUE}正在构建${build_type}静态库 ${lib_name}...${NC}"

    # 确保依赖的yaml-cpp静态库存在
    ensure_yaml_static_lib $debug
    if [ $? -ne 0 ]; then
        return 1
    fi

    # 复制yaml-cpp的头文件和库文件到dist目录
    cp "$YAML_LIB_HEADER" "$DIST_DIR/include/"

    if [ "$debug" = "debug" ]; then
        cp "$YAML_STATIC_DEBUG_LIB" "$DIST_DIR/lib/"
    else
        cp "$YAML_STATIC_LIB" "$DIST_DIR/lib/"
    fi

    # 复制yamjson的头文件到dist目录
    cp "$HEADER" "$DIST_DIR/include/"
    cp "$JSON_LIB" "$DIST_DIR/include/"

    # 编译源文件
    g++ -std=c++11 $build_flags -I"$HEADER_DIR" -I"$EXT_DIR" -I"$YAML_MODULE/include" -c "$SOURCE" -o "$DIST_DIR/yamjson.o"

    # 创建静态库
    ar rcs "$DIST_DIR/lib/$lib_name" "$DIST_DIR/yamjson.o"

    # 清理临时文件
    rm -f "$DIST_DIR/yamjson.o"

    echo -e "${GREEN}✓ ${build_type}静态库已生成：$DIST_DIR/lib/$lib_name${NC}"

    # 创建测试脚本
    if [ "$debug" = "debug" ]; then
        create_test_script "static-debug"
    else
        create_test_script "static"
    fi

    return 0
}

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

    echo -e "${BLUE}正在构建${build_type}动态库 ${lib_name}...${NC}"

    # 确保依赖的yaml-cpp动态库存在
    ensure_yaml_shared_lib $debug
    if [ $? -ne 0 ]; then
        return 1
    fi

    # 复制yaml-cpp的头文件和库文件到dist目录
    cp "$YAML_LIB_HEADER" "$DIST_DIR/include/"

    if [ "$debug" = "debug" ]; then
        cp "$YAML_SHARED_DEBUG_LIB" "$DIST_DIR/lib/"
    else
        cp "$YAML_SHARED_LIB" "$DIST_DIR/lib/"
    fi

    # 复制yamjson的头文件到dist目录
    cp "$HEADER" "$DIST_DIR/include/"
    cp "$JSON_LIB" "$DIST_DIR/include/"

    # 编译创建动态库
    g++ -std=c++11 $build_flags -I"$HEADER_DIR" -I"$EXT_DIR" -I"$YAML_MODULE/include" -fPIC -shared "$SOURCE" -o "$DIST_DIR/lib/$lib_name" -L"$YAML_MODULE/lib" -l$yaml_lib

    echo -e "${GREEN}✓ ${build_type}动态库已生成：$DIST_DIR/lib/$lib_name${NC}"

    # 创建测试脚本
    if [ "$debug" = "debug" ]; then
        create_test_script "shared-debug"
    else
        create_test_script "shared"
    fi

    return 0
}

# 函数: 生成README文件
generate_readme() {
    local readme="$DIST_DIR/README.md"

    echo -e "${BLUE}生成使用说明文件...${NC}"

    echo "# YamJSON 库" > "$readme"
    echo "" >> "$readme"
    echo "YAML 与 JSON 相互转换的 C++ 库" >> "$readme"
    echo "" >> "$readme"
    echo "## 可用版本" >> "$readme"
    echo "" >> "$readme"

    if [ -f "$DIST_DIR/include/$SINGLE_HEADER" ]; then
        echo "### 单头文件版本" >> "$readme"
        echo "" >> "$readme"
        echo "文件: \`include/yamjson.hpp\`" >> "$readme"
        echo "" >> "$readme"
        echo "使用方法:" >> "$readme"
        echo '```cpp' >> "$readme"
        echo "// 在所有需要使用 yamjson 的文件中:" >> "$readme"
        echo "#include \"yamjson.hpp\"" >> "$readme"
        echo "" >> "$readme"
        echo "// 在且仅在一个源文件中添加以下代码:" >> "$readme"
        echo "#define YAMJSON_IMPLEMENTATION" >> "$readme"
        echo "#include \"yamjson.hpp\"" >> "$readme"
        echo '```' >> "$readme"
        echo "" >> "$readme"
    fi

    if [ -f "$DIST_DIR/lib/libyamjson.a" ]; then
        echo "### 静态库版本" >> "$readme"
        echo "" >> "$readme"
        echo "文件:" >> "$readme"
        echo "- \`include/yamjson.h\` - 头文件" >> "$readme"
        echo "- \`lib/libyaml.a\` - YAML-CPP 静态库" >> "$readme"
        echo "- \`lib/libyamjson.a\` - YamJSON 静态库" >> "$readme"
        echo "" >> "$readme"
        echo "使用方法:" >> "$readme"
        echo '```cpp' >> "$readme"
        echo "#include \"yamjson.h\"" >> "$readme"
        echo '```' >> "$readme"
        echo "" >> "$readme"
        echo "编译命令:" >> "$readme"
        echo '```bash' >> "$readme"
        echo "g++ your_file.cpp -o your_program -I./include -L./lib -lyamjson -lyaml" >> "$readme"
        echo '```' >> "$readme"
        echo "" >> "$readme"
    fi

    if [ -f "$DIST_DIR/lib/libyamjson-debug.a" ]; then
        echo "### 静态库调试版本" >> "$readme"
        echo "" >> "$readme"
        echo "文件:" >> "$readme"
        echo "- \`include/yamjson.h\` - 头文件" >> "$readme"
        echo "- \`lib/libyaml-debug.a\` - YAML-CPP 调试版静态库" >> "$readme"
        echo "- \`lib/libyamjson-debug.a\` - YamJSON 调试版静态库" >> "$readme"
        echo "" >> "$readme"
        echo "使用方法:" >> "$readme"
        echo '```cpp' >> "$readme"
        echo "#include \"yamjson.h\"" >> "$readme"
        echo '```' >> "$readme"
        echo "" >> "$readme"
        echo "编译命令:" >> "$readme"
        echo '```bash' >> "$readme"
        echo "g++ -g your_file.cpp -o your_program -I./include -L./lib -lyamjson-debug -lyaml-debug" >> "$readme"
        echo '```' >> "$readme"
        echo "" >> "$readme"
    fi

    if [ -f "$DIST_DIR/lib/libyamjson.so" ]; then
        echo "### 动态库版本" >> "$readme"
        echo "" >> "$readme"
        echo "文件:" >> "$readme"
        echo "- \`include/yamjson.h\` - 头文件" >> "$readme"
        echo "- \`lib/libyaml.so\` - YAML-CPP 动态库" >> "$readme"
        echo "- \`lib/libyamjson.so\` - YamJSON 动态库" >> "$readme"
        echo "" >> "$readme"
        echo "使用方法:" >> "$readme"
        echo '```cpp' >> "$readme"
        echo "#include \"yamjson.h\"" >> "$readme"
        echo '```' >> "$readme"
        echo "" >> "$readme"
        echo "编译命令:" >> "$readme"
        echo '```bash' >> "$readme"
        echo "g++ your_file.cpp -o your_program -I./include -L./lib -lyamjson -lyaml" >> "$readme"
        echo "LD_LIBRARY_PATH=./lib ./your_program  # 设置运行时库路径" >> "$readme"
        echo '```' >> "$readme"
        echo "" >> "$readme"
    fi

    if [ -f "$DIST_DIR/lib/libyamjson-debug.so" ]; then
        echo "### 动态库调试版本" >> "$readme"
        echo "" >> "$readme"
        echo "文件:" >> "$readme"
        echo "- \`include/yamjson.h\` - 头文件" >> "$readme"
        echo "- \`lib/libyaml-debug.so\` - YAML-CPP 调试版动态库" >> "$readme"
        echo "- \`lib/libyamjson-debug.so\` - YamJSON 调试版动态库" >> "$readme"
        echo "" >> "$readme"
        echo "使用方法:" >> "$readme"
        echo '```cpp' >> "$readme"
        echo "#include \"yamjson.h\"" >> "$readme"
        echo '```' >> "$readme"
        echo "" >> "$readme"
        echo "编译命令:" >> "$readme"
        echo '```bash' >> "$readme"
        echo "g++ -g your_file.cpp -o your_program -I./include -L./lib -lyamjson-debug -lyaml-debug" >> "$readme"
        echo "LD_LIBRARY_PATH=./lib ./your_program  # 设置运行时库路径" >> "$readme"
        echo '```' >> "$readme"
        echo "" >> "$readme"
    fi

    echo "## 测试脚本" >> "$readme"
    echo "" >> "$readme"
    echo "使用提供的测试脚本验证库是否正常工作:" >> "$readme"
    echo "" >> "$readme"
    echo '```bash' >> "$readme"
    echo "./test_yamjson.sh" >> "$readme"
    echo '```' >> "$readme"

    echo -e "${GREEN}✓ 使用说明文件已生成：$readme${NC}"
}

# 主函数
main() {
    # 检查依赖
    check_dependencies
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # 如果没有参数，提供交互式选择
    if [ $# -eq 0 ]; then
        echo -e "${BLUE}请选择要构建的版本:${NC}"
        echo "1) 单头文件版本 (默认)"
        echo "2) 静态库版本 (发布版)"
        echo "3) 静态库版本 (调试版)"
        echo "4) 动态库版本 (发布版)"
        echo "5) 动态库版本 (调试版)"
        echo "6) 所有版本"
        read -p "请选择 [1-6] (默认 1): " choice

        choice=${choice:-1}

        case $choice in
            1)
                generate_single_header
                generate_readme
                ;;
            2)
                build_static_lib
                generate_readme
                ;;
            3)
                build_static_lib debug
                generate_readme
                ;;
            4)
                build_shared_lib
                generate_readme
                ;;
            5)
                build_shared_lib debug
                generate_readme
                ;;
            6)
                generate_single_header
                build_static_lib
                build_static_lib debug
                build_shared_lib
                build_shared_lib debug
                generate_readme
                ;;
            *)
                echo -e "${RED}无效选择!${NC}"
                exit 1
                ;;
        esac

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
                generate_single_header
                ;;
            -t|--static)
                build_static_lib
                ;;
            -td|--static-debug)
                build_static_lib debug
                ;;
            -d|--shared)
                build_shared_lib
                ;;
            -dd|--shared-debug)
                build_shared_lib debug
                ;;
            -a|--all)
                generate_single_header
                build_static_lib
                build_static_lib debug
                build_shared_lib
                build_shared_lib debug
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
    generate_readme
}

# 执行主函数
main "$@"