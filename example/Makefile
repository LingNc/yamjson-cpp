# yamjson 示例代码 Makefile

# 编译器选项
CXX = g++
CXXFLAGS = -std=c++11 -Wall

# 目标文件
TARGET = yamjson_example
DIST_DIR = ../dist

# 默认目标: 根据dist目录中的可用版本构建示例
all: check_dist single static shared

# 检查dist目录是否存在，不存在则生成单头文件版本
check_dist:
	@if [ ! -d "$(DIST_DIR)" ] || [ ! -f "$(DIST_DIR)/include/yamjson.hpp" -a ! -f "$(DIST_DIR)/include/yamjson.h" ]; then \
		echo "构建yamjson库..."; \
		cd .. && ./tools/build_yamjson.sh --single; \
	fi

# 使用单头文件版本构建
single: $(DIST_DIR)/include/yamjson.hpp
	@echo "构建单头文件版本示例..."
	@echo "#define YAMJSON_IMPLEMENTATION" > yamjson_example_single.cpp
	@cat yamjson_example.cpp | sed 's|#include.*|#include "../dist/include/yamjson.hpp"|' >> yamjson_example_single.cpp
	$(CXX) $(CXXFLAGS) -I$(DIST_DIR) -o $(TARGET)_single yamjson_example_single.cpp
	@echo "单头文件示例构建完成: $(TARGET)_single"

# 使用静态库版本构建
static: $(DIST_DIR)/lib/libyamjson.a
	@echo "构建静态库版本示例..."
	@cat yamjson_example.cpp | sed 's|#include.*|#include "../dist/include/yamjson.h"|' > yamjson_example_static.cpp
	$(CXX) $(CXXFLAGS) -I$(DIST_DIR) -o $(TARGET)_static yamjson_example_static.cpp -L$(DIST_DIR)/lib -lyamjson -lyaml
	@echo "静态库示例构建完成: $(TARGET)_static"

# 使用共享库版本构建
shared: $(DIST_DIR)/lib/libyamjson.so
	@echo "构建共享库版本示例..."
	@cat yamjson_example.cpp | sed 's|#include.*|#include "../dist/include/yamjson.h"|' > yamjson_example_shared.cpp
	$(CXX) $(CXXFLAGS) -I$(DIST_DIR) -o $(TARGET)_shared yamjson_example_shared.cpp -L$(DIST_DIR)/lib -lyamjson -lyaml
	@echo "共享库示例构建完成: $(TARGET)_shared (运行前需要设置 LD_LIBRARY_PATH=$(DIST_DIR)/lib)"

# 条件目标：仅当文件存在时才执行
$(DIST_DIR)/include/yamjson.hpp:
	@if [ ! -f "$(DIST_DIR)/include/yamjson.hpp" ]; then \
		echo "生成单头文件版本..."; \
		cd .. && ./tools/build_yamjson.sh --single; \
	fi

$(DIST_DIR)/lib/libyamjson.a:
	@if [ ! -f "$(DIST_DIR)/lib/libyamjson.a" ]; then \
		echo "生成静态库版本..."; \
		cd .. && ./tools/build_yamjson.sh --static; \
	fi

$(DIST_DIR)/lib/libyamjson.so:
	@if [ ! -f "$(DIST_DIR)/lib/libyamjson.so" ]; then \
		echo "生成共享库版本..."; \
		cd .. && ./tools/build_yamjson.sh --shared; \
	fi

# 运行示例程序
run_single: single
	@echo "运行单头文件版本示例..."
	./$(TARGET)_single

run_static: static
	@echo "运行静态库版本示例..."
	./$(TARGET)_static

run_shared: shared
	@echo "运行共享库版本示例..."
	LD_LIBRARY_PATH=$(DIST_DIR)/lib ./$(TARGET)_shared

# 清理生成的文件
clean:
	rm -f $(TARGET)_single $(TARGET)_static $(TARGET)_shared *.o yamjson_example_*.cpp

# 声明伪目标
.PHONY: all check_dist single static shared run_single run_static run_shared clean
