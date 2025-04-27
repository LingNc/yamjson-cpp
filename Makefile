# yamjson Makefile - 用于构建单头文件版本

# 路径定义
HEADER_DIR = include
SRC_DIR = src
DIST_DIR = dist
EXAMPLE_DIR = example

# 源文件
HEADER = $(HEADER_DIR)/yamjson.h
SOURCE = $(SRC_DIR)/yamjson.cpp
SINGLE_HEADER = yamjson.hpp

# 确保输出目录存在
$(shell mkdir -p $(DIST_DIR))

# 默认目标：生成单头文件
all: $(DIST_DIR)/$(SINGLE_HEADER)

# 生成单头文件版本
$(DIST_DIR)/$(SINGLE_HEADER): $(HEADER) $(SOURCE)
@echo "生成单头文件版本 $(SINGLE_HEADER)..."
@echo "// yamjson single header - generated on $$(date)" > $(DIST_DIR)/$(SINGLE_HEADER)
@echo "// https://github.com/username/yamjson" >> $(DIST_DIR)/$(SINGLE_HEADER)
@echo "// MIT License" >> $(DIST_DIR)/$(SINGLE_HEADER)
@echo "#pragma once" >> $(DIST_DIR)/$(SINGLE_HEADER)
@echo "" >> $(DIST_DIR)/$(SINGLE_HEADER)

# 提取头文件中的所有 #include 语句
@grep "#include" $(HEADER) | grep -v "\"yamjson.h\"" >> $(DIST_DIR)/$(SINGLE_HEADER)
@echo "" >> $(DIST_DIR)/$(SINGLE_HEADER)

# 添加头文件内容（忽略 #pragma once 和 #include 语句）
@cat $(HEADER) | grep -v "#pragma once" | grep -v "#include" >> $(DIST_DIR)/$(SINGLE_HEADER)
@echo "" >> $(DIST_DIR)/$(SINGLE_HEADER)

# 添加源文件内容（忽略 #include 语句），并给所有函数添加 inline 关键字
@cat $(SOURCE) | grep -v "#include" | sed 's/^[a-zA-Z_].*::.*(/inline &/' \
| sed 's/^[a-zA-Z_][a-zA-Z0-9_]* [a-zA-Z_][a-zA-Z0-9_]*::.*(/inline &/' \
| sed 's/^YAML::Node /inline YAML::Node /' \
| sed 's/^nlohmann::json /inline nlohmann::json /' \
| sed 's/^std::string /inline std::string /' \
| sed 's/^bool /inline bool /' \
>> $(DIST_DIR)/$(SINGLE_HEADER)

@echo "单头文件版本已生成：$(DIST_DIR)/$(SINGLE_HEADER)"

# 构建示例
example: $(DIST_DIR)/$(SINGLE_HEADER)
$(MAKE) -C $(EXAMPLE_DIR)

# 清理生成的文件
clean:
rm -rf $(DIST_DIR)
$(MAKE) -C $(EXAMPLE_DIR) clean

# 安装：复制单头文件到系统目录（需要sudo权限）
install: $(DIST_DIR)/$(SINGLE_HEADER)
@echo "安装yamjson单头文件..."
@mkdir -p /usr/local/include/yamjson
@cp $(DIST_DIR)/$(SINGLE_HEADER) /usr/local/include/yamjson/
@echo "安装完成！"

.PHONY: all clean example install
