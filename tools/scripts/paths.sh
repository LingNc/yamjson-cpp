#!/bin/bash
# paths.sh - 路径和文件定义

# 导入日志模块
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

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