# yamjson Makefile - 用于构建单头文件版本

# 路径定义
HEADER_DIR = include
SRC_DIR = src
DIST_DIR = dist
EXAMPLE_DIR = example
TOOLS_DIR = tools

# 源文件
HEADER = $(HEADER_DIR)/yamjson.h
SOURCE = $(SRC_DIR)/yamjson.cpp
SINGLE_HEADER = yamjson.hpp
BUILD_SCRIPT = $(TOOLS_DIR)/build_yamjson.sh

# 确保输出目录存在
$(shell mkdir -p $(DIST_DIR))

# 确保构建脚本可执行
$(shell chmod +x $(BUILD_SCRIPT))

# 默认目标: help
default : help

# 显示帮助信息
.PHONY : help
help:
	@echo "yamjson 构建工具帮助"
	@echo "===================="
	@echo "使用命令:"
	@echo "  make              - 显示此帮助信息"
	@echo "  make all          - 构建所有版本"
	@echo "  make merged       - 构建单一头文件版本"
	@echo "  make static       - 构建静态库版本"
	@echo "  make static-debug - 构建调试版静态库"
	@echo "  make shared       - 构建动态库版本"
	@echo "  make shared-debug - 构建调试版动态库"
	@echo "  make build-all    - 构建所有版本"
	@echo "  make example      - 构建示例程序"
	@echo "  make clean        - 清理构建文件"
	@echo "  make install      - 安装到系统目录"
	@echo ""
	@echo "或者直接使用构建脚本 (更多选项):"
	@echo "  ./$(BUILD_SCRIPT) [选项]"


# 构建所有
.PHONY : all
all :
	merged
	static
	static-debug
	shared
	shared-debug

# 生成单头文件
.PHONY : merged
merged: $(BUILD_SCRIPT)
	@$(BUILD_SCRIPT) --single

# 构建静态库
.PHONY : static
static: $(BUILD_SCRIPT)
	@$(BUILD_SCRIPT) --static

# 构建调试版静态库
.PHONY : static-debug
static-debug: $(BUILD_SCRIPT)
	@$(BUILD_SCRIPT) --static-debug

# 构建动态库
.PHONY : shared
shared: $(BUILD_SCRIPT)
	@$(BUILD_SCRIPT) --shared

# 构建调试版动态库
.PHONY : shared-debug
shared-debug: $(BUILD_SCRIPT)
	@$(BUILD_SCRIPT) --shared-debug

# 构建所有版本
.PHONY : build-all
build-all: $(BUILD_SCRIPT)
	@$(BUILD_SCRIPT) --all

# 构建示例
.PHONY : example
example: all
	$(MAKE) -C $(EXAMPLE_DIR)

# 清理生成的文件
.PHONY : clean
clean:
	rm -rf $(DIST_DIR)
	$(MAKE) -C $(EXAMPLE_DIR) clean

# 安装：复制单头文件到系统目录（需要sudo权限）
.PHONY : install
install: all
	@echo "安装yamjson单头文件..."
	@mkdir -p /usr/local/include/yamjson
	@cp $(DIST_DIR)/$(SINGLE_HEADER) /usr/local/include/yamjson/
	@echo "安装完成！"
