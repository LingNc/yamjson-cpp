#!/bin/bash
# common.sh - 共享的变量和函数

# 颜色定义
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;36m'
export NC='\033[0m' # 无颜色

# 路径定义
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
export TOOLS_DIR="$(dirname "$SCRIPT_DIR")"
export ROOT_DIR="$(dirname "$TOOLS_DIR")"
export HEADER_DIR="$ROOT_DIR/include"
export SRC_DIR="$ROOT_DIR/src"
export DIST_DIR="$ROOT_DIR/dist"
export EXT_DIR="$ROOT_DIR/ext"
export LIB_DIR="$ROOT_DIR/lib"
export MODULE_DIR="$ROOT_DIR/module"
export YAML_MODULE="$MODULE_DIR/yaml-cpp-builder"

# 文件定义
export HEADER="$HEADER_DIR/yamjson.h"
export SOURCE="$SRC_DIR/yamjson.cpp"
export SINGLE_HEADER="yamjson.hpp"
export JSON_LIB="$EXT_DIR/json.hpp"
export YAML_SINGLE_HEADER="$YAML_MODULE/include/yaml-cpp.hpp"
export YAML_LIB_HEADER="$YAML_MODULE/include/yaml.hpp"
export YAML_STATIC_LIB="$YAML_MODULE/lib/libyaml.a"
export YAML_STATIC_DEBUG_LIB="$YAML_MODULE/lib/libyaml-debug.a"
export YAML_SHARED_LIB="$YAML_MODULE/lib/libyaml.so"
export YAML_SHARED_DEBUG_LIB="$YAML_MODULE/lib/libyaml-debug.so"

# 创建必要的目录
mkdir -p "$DIST_DIR/include"
mkdir -p "$DIST_DIR/lib"
mkdir -p "$LIB_DIR"
mkdir -p "$EXT_DIR"

# 函数: 显示彩色消息
log_info() {
    echo -e "${BLUE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}警告: $1${NC}"
}

log_error() {
    echo -e "${RED}错误: $1${NC}"
}

# 函数: 链接yaml-cpp单头文件到ext目录（用于单头文件构建）
link_yaml_single_header() {
    log_info "链接yaml-cpp单头文件到ext目录..."

    # 创建到yaml-cpp.hpp的链接
    if [ -f "$YAML_SINGLE_HEADER" ]; then
        ln -sf "$YAML_SINGLE_HEADER" "$EXT_DIR/yaml-cpp.hpp"
        log_success "已链接 yaml-cpp.hpp 到 ext 目录"
    else
        log_warning "找不到 yaml-cpp.hpp，无法创建链接"
    fi
}

# 函数: 链接yaml.hpp头文件到ext目录（用于库构建）
link_yaml_lib_header() {
    log_info "链接yaml.hpp头文件到ext目录..."

    # 创建到yaml.hpp的链接
    if [ -f "$YAML_LIB_HEADER" ]; then
        ln -sf "$YAML_LIB_HEADER" "$EXT_DIR/yaml.hpp"
        log_success "已链接 yaml.hpp 到 ext 目录"
    else
        log_warning "找不到 yaml.hpp，无法创建链接"
    fi
}

# 函数: 链接yaml-cpp库文件到lib目录
link_yaml_libs() {
    local debug=$1
    local lib_type=${2:-"static"}  # 默认为静态库，可选值: static 或 shared

    log_info "链接yaml-cpp库文件到lib目录..."

    if [ "$debug" = "debug" ]; then
        # 链接调试版静态库
        if [ -f "$YAML_STATIC_DEBUG_LIB" ]; then
            ln -sf "$YAML_STATIC_DEBUG_LIB" "$LIB_DIR/libyaml-debug.a"
            log_success "已链接 libyaml-debug.a 到 lib 目录"
        else
            log_warning "找不到 libyaml-debug.a，无法创建链接"
        fi

        # 只有在共享库模式下才链接 .so 文件
        if [ "$lib_type" = "shared" ]; then
            if [ -f "$YAML_SHARED_DEBUG_LIB" ]; then
                ln -sf "$YAML_SHARED_DEBUG_LIB" "$LIB_DIR/libyaml-debug.so"
                log_success "已链接 libyaml-debug.so 到 lib 目录"
            else
                log_warning "找不到 libyaml-debug.so，无法创建链接"
            fi
        fi
    else
        # 链接发布版静态库
        if [ -f "$YAML_STATIC_LIB" ]; then
            ln -sf "$YAML_STATIC_LIB" "$LIB_DIR/libyaml.a"
            log_success "已链接 libyaml.a 到 lib 目录"
        else
            log_warning "找不到 libyaml.a，无法创建链接"
        fi

        # 只有在共享库模式下才链接 .so 文件
        if [ "$lib_type" = "shared" ]; then
            if [ -f "$YAML_SHARED_LIB" ]; then
                ln -sf "$YAML_SHARED_LIB" "$LIB_DIR/libyaml.so"
                log_success "已链接 libyaml.so 到 lib 目录"
            else
                log_warning "找不到 libyaml.so，无法创建链接"
            fi
        fi
    fi
}

# 函数: 检查依赖
check_dependencies() {
    log_info "正在检查依赖..."

    # 检查 json.hpp
    if [ ! -f "$JSON_LIB" ]; then
        log_error "找不到 json.hpp 文件!"
        echo -e "请下载 nlohmann/json 库放置到 $JSON_LIB 位置:"
        echo -e "${YELLOW}wget https://github.com/nlohmann/json/releases/download/v3.11.2/json.hpp -O $JSON_LIB${NC}"
        return 1
    else
        log_success "json.hpp 已找到"
    fi

    # 检查 yaml-cpp-builder 模块
    if [ ! -d "$YAML_MODULE" ]; then
        log_error "找不到 yaml-cpp-builder 模块!"
        echo -e "请初始化并更新子模块:"
        echo -e "${YELLOW}git submodule init && git submodule update${NC}"
        return 1
    else
        log_success "yaml-cpp-builder 模块已找到"
    fi

    return 0
}

# 函数: 确保yaml-cpp单头文件存在
ensure_yaml_single_header() {
    if [ ! -f "$YAML_SINGLE_HEADER" ]; then
        log_warning "找不到 yaml-cpp.hpp 单头文件!"
        read -p "是否构建 yaml-cpp 单头文件? (Y/n): " build_yaml
        build_yaml=${build_yaml:-Y}

        if [[ $build_yaml =~ ^[Yy]$ ]]; then
            log_info "正在构建 yaml-cpp 单头文件..."
            (cd "$YAML_MODULE" && make merged-header)

            if [ ! -f "$YAML_SINGLE_HEADER" ]; then
                log_error "yaml-cpp.hpp 构建失败!"
                return 1
            else
                log_success "yaml-cpp.hpp 已成功构建"
                # 只链接单头文件版本
                link_yaml_single_header
            fi
        else
            log_error "需要 yaml-cpp.hpp 才能继续!"
            return 1
        fi
    else
        log_success "yaml-cpp.hpp 已找到"
        # 只链接单头文件版本
        link_yaml_single_header
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
        log_warning "找不到 yaml-cpp 静态库 ($lib_name) 或头文件!"
        read -p "是否构建 yaml-cpp 静态库? (Y/n): " build_yaml
        build_yaml=${build_yaml:-Y}

        if [[ $build_yaml =~ ^[Yy]$ ]]; then
            log_info "正在构建 yaml-cpp 静态库..."
            (cd "$YAML_MODULE" && $build_cmd)

            if [ ! -f "$lib_path" ] || [ ! -f "$YAML_LIB_HEADER" ]; then
                log_error "yaml-cpp 静态库构建失败!"
                return 1
            else
                log_success "yaml-cpp 静态库已成功构建"
                # 链接yaml.hpp头文件和库文件
                link_yaml_lib_header
                link_yaml_libs $debug "static"
            fi
        else
            log_error "需要 yaml-cpp 静态库才能继续!"
            return 1
        fi
    else
        log_success "yaml-cpp 静态库 ($lib_name) 已找到"
        # 链接yaml.hpp头文件和库文件
        link_yaml_lib_header
        link_yaml_libs $debug "static"
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
        log_warning "找不到 yaml-cpp 动态库 ($lib_name) 或头文件!"
        read -p "是否构建 yaml-cpp 动态库? (Y/n): " build_yaml
        build_yaml=${build_yaml:-Y}

        if [[ $build_yaml =~ ^[Yy]$ ]]; then
            log_info "正在构建 yaml-cpp 动态库..."
            (cd "$YAML_MODULE" && $build_cmd)

            if [ ! -f "$lib_path" ] || [ ! -f "$YAML_LIB_HEADER" ]; then
                log_error "yaml-cpp 动态库构建失败!"
                return 1
            else
                log_success "yaml-cpp 动态库已成功构建"
                # 链接yaml.hpp头文件和库文件
                link_yaml_lib_header
                link_yaml_libs $debug "shared"
            fi
        else
            log_error "需要 yaml-cpp 动态库才能继续!"
            return 1
        fi
    else
        log_success "yaml-cpp 动态库 ($lib_name) 已找到"
        # 链接yaml.hpp头文件和库文件
        link_yaml_lib_header
        link_yaml_libs $debug "shared"
    fi

    return 0
}

# 函数: 创建测试脚本
create_test_script() {
    local type=$1
    local script_file="$DIST_DIR/test_yamjson.sh"

    log_info "创建测试脚本: ${script_file}..."

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
    log_success "测试脚本已创建: $script_file"
}