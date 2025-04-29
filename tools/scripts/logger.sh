#!/bin/bash
# logger.sh - 日志输出相关函数

# 颜色定义
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;36m'
export NC='\033[0m' # 无颜色

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