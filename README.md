# yamjson

yamjson 是一个轻量级 YAML 与 JSON 转换库，基于 yaml-cpp 和 nlohmann/json 开发，提供了方便的转换接口和保留注释的 YAML 处理能力。

## 特性

- 支持 YAML 到 JSON 的双向转换
- 保留 YAML 文件中的注释信息
- 提供友好的 C++ API，与 nlohmann/json 无缝集成
- 支持单头文件版本，方便项目集成
- 提供美化工具，方便调试和可视化

## 依赖

- [yaml-cpp](https://github.com/jbeder/yaml-cpp)
- [nlohmann/json](https://github.com/nlohmann/json)

## 使用方法

### 1. 标准头文件和源文件方式

```cpp
#include <yamjson.h>

// YAML转JSON
std::string yaml_str = "key: value\nlist:\n  - item1\n  - item2";
nlohmann::json j = yamjson::yaml_to_json(yaml_str);

// JSON转YAML
std::string yaml_output = yamjson::json_to_yaml(j);
```

### 2. 单头文件方式

```cpp
#include <yamjson.hpp>

// 直接使用全部功能，所有函数已内联
nlohmann::json j = yamjson::yaml_to_json(yaml_str);
```

### 3. 保留注释的YAML文档

```cpp
// 从文件加载YAML（保留注释）
auto doc = nlohmann::yaml::document::from_file("config.yaml");

// 修改值
doc["settings"]["timeout"] = 30;

// 保存回文件（保留原始注释）
doc.save();
```

## 构建

构建单头文件版本：

```bash
make
```

编译示例代码：

```bash
make example
```

清理构建文件：

```bash
make clean
```

## 工具

yamjson 提供了一个美化工具 `tools/yamjson.py`，可用于格式化和可视化 YAML/JSON 数据。

## 协议

该项目采用 MIT 协议开源。
