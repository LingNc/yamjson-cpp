#!/bin/bash
# yaml_deps.sh - YAML依赖管理相关函数

# 导入必要的模块
source "$(dirname "${BASH_SOURCE[0]}")/paths.sh"

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