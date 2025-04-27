#pragma once
#include <string>
#include <map>
#include <vector>
#include <memory>
#include <fstream>
#include <sstream>
#include "json.hpp"
#include "yaml.hpp"

namespace yamjson{
    // YAML -> JSON 核心转换函数
    nlohmann::json yaml_to_json(const std::string &yaml_str);
    nlohmann::json yaml_node_to_json(const YAML::Node &node);

    // JSON -> YAML 核心转换函数
    std::string json_to_yaml(const nlohmann::json &j);
    YAML::Node json_to_yaml_node(const nlohmann::json &j);

    // 保留注释的YAML转换
    class YamlDocument{
    private:
        std::string original_yaml_;  // 保存原始YAML文本，包含注释
        nlohmann::json json_data_;   // 保存转换后的JSON数据

    public:
        // 构造函数
        explicit YamlDocument(const std::string &yaml_content);
        YamlDocument()=default;

        // 获取JSON数据
        const nlohmann::json &json() const{ return json_data_; }
        nlohmann::json &json(){ return json_data_; }

        // 获取原始YAML，包含注释
        const std::string &original_yaml() const{ return original_yaml_; }

        // 应用JSON修改并生成新的YAML（保留注释）
        std::string dump() const;

        // 修改特定路径的值，返回是否成功修改
        bool update_value(const std::vector<std::string> &path,const nlohmann::json &value);
    };
}

// 以下是与 nlohmann::json 集成的函数，基于 ADL 机制
namespace nlohmann{
    // 从 YAML 字符串解析
    inline void from_yaml(const std::string &yaml_str,json &j){
        j=yamjson::yaml_to_json(yaml_str);
    }

    // YAML 字符串 -> 任意类型 (遵循 from_json 的模式)
    template<typename ValueType>
    inline void from_yaml(const std::string &yaml_str,ValueType &val){
        json j=yamjson::yaml_to_json(yaml_str);
        j.get_to(val);  // 使用 json 的 get_to 方法
    }

    // 将 JSON 转换为 YAML 字符串
    inline std::string to_yaml(const json &j){
        return yamjson::json_to_yaml(j);
    }
}

// 为与 YAML 相关的类型提供 ADL 序列化器
namespace nlohmann{
    // 单独的命名空间，存放 YAML 相关的类型
    namespace yaml{
        // 包装类，表示一个 YAML 文档（保留注释版本）
        class document{
        private:
            std::shared_ptr<yamjson::YamlDocument> doc_;
            std::string file_path_; // 文件路径，用于读写操作

        public:
            // 从 YAML 字符串构造
            explicit document(const std::string &yaml_content);

            // 从文件路径构造
            static document from_file(const std::string &file_path);

            // 默认构造函数
            document();

            // 获取JSON数据
            nlohmann::json &get_json();
            const nlohmann::json &get_json() const;

            // 生成YAML（保留注释）
            std::string dump() const;

            // 修改特定路径的值
            bool update(const std::vector<std::string> &path,const nlohmann::json &value);

            // 快捷访问接口，保持与原始接口兼容
            std::string content() const;

            // 重载[]运算符，用于访问JSON数据
            template<typename T>
            auto operator[](T &&key) -> decltype(get_json()[std::forward<T>(key)]){
                return get_json()[std::forward<T>(key)];
            }

            template<typename T>
            auto operator[](T &&key) const -> decltype(get_json()[std::forward<T>(key)]){
                return get_json()[std::forward<T>(key)];
            }

            // 重载=运算符，用于赋值JSON数据
            document &operator=(const nlohmann::json &j);

            // 将YAML内容写入文件
            bool save() const;

            // 将YAML内容写入指定文件
            bool save_to(const std::string &file_path) const;

            // 设置文件路径
            void set_file_path(const std::string &file_path);

            // 获取文件路径
            const std::string &get_file_path() const;

            // 重新从文件加载
            bool reload();
        };
    }

    // 为 YAML 文档类型特化 ADL 序列化器
    template<>
    struct adl_serializer<yaml::document>;
}
