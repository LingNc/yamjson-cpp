# yamjson 示例代码 Makefile

# 编译器选项
CXX = g++
CXXFLAGS = -std=c++17 -Wall -I../include -I/usr/local/include

# 链接选项
LDFLAGS = -L/usr/local/lib -lyaml-cpp

# 目标和源文件
TARGET = yamjson_example
SRCS = yamjson_example.cpp ../src/yamjson.cpp

# 单头文件示例
SINGLE_TARGET = yamjson_single_example
SINGLE_SRCS = yamjson_example_single.cpp

# 默认目标
all: $(TARGET)

# 使用标准方式构建
$(TARGET): $(SRCS)
$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS)

# 使用单头文件方式构建
single: $(SINGLE_TARGET)

$(SINGLE_TARGET): yamjson_example_single.cpp ../dist/yamjson_single.hpp
cp yamjson_example.cpp yamjson_example_single.cpp
sed -i 's|../include/yamjson.h|../dist/yamjson_single.hpp|' yamjson_example_single.cpp
$(CXX) $(CXXFLAGS) -o $@ $(SINGLE_SRCS)

# 先确保单头文件存在
../dist/yamjson_single.hpp:
cd .. && $(MAKE)

# 清理生成的文件
clean:
rm -f $(TARGET) $(SINGLE_TARGET) *.o *.yaml yamjson_example_single.cpp

.PHONY: all clean single
