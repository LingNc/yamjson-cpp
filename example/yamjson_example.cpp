#include <iostream>
#include <fstream>
#include <string>
#include "../include/yamjson.h"

/**
 * YamJSON 库使用示例
 * 本例展示如何使用 YamJSON 类在 YAML 和 JSON 之间进行转换
 * 包括保留注释和不同格式输出方式
 */
int main() {
    try {
        // 带注释的示例YAML字符串
        std::string yaml_str = R"(
# 服务器配置部分
server:
  host: 127.0.0.1  # 主机地址
  port: 8080       # 监听端口
  debug: true      # 是否开启调试模式

# 存储配置部分
storage:
  type: local       # 存储类型：local或remote
  path: /var/data   # 本地存储路径
  options:          # 存储选项
    - cache         # 启用缓存
    - compress      # 启用压缩

# 用户配置部分
users:
  - name: admin     # 管理员用户
    roles: [admin, user]
  - name: guest     # 访客用户
    roles: [user]
        )";

        std::cout << "===== YamJSON 功能演示 =====" << std::endl;
        std::cout << "\n原始YAML内容：\n" << yaml_str << std::endl;

        // ===== 方式1：从字符串创建 YamJSON 对象 =====
        std::cout << "\n\n===== 方式1：从YAML字符串创建并保留注释 =====" << std::endl;

        // 使用静态工厂方法创建 YamJSON 对象
        yamjson::YamJSON config = yamjson::YamJSON::parse(yaml_str);
        // 也可以使用 yamjson::YamJSON::from_yaml(yaml_str);

        // 转换为 JSON 并打印
        nlohmann::json json_data = config.to_json();
        std::cout << "解析后的JSON格式:\n" << json_data.dump(2) << std::endl;

        // 使用 [] 操作符修改数据
        config["server"]["port"] = 9000;
        config["server"]["debug"] = false;

        // 使用路径更新API修改数据
        config.update_value({"storage", "type"}, "remote");
        config.update_value({"storage", "options"}, nlohmann::json::array({"cache", "compress", "encrypt"}));

        // 以YAML格式输出（保留注释）
        std::string updated_yaml = config.to_yaml();
        std::cout << "\n修改后的YAML（保留了注释）:\n" << updated_yaml << std::endl;

        // 保存到文件
        config.save_to("config_with_comments.yaml");
        std::cout << "已将带注释的配置保存到 config_with_comments.yaml" << std::endl;

        // ===== 方式2：美观的输出格式 =====
        std::cout << "\n\n===== 方式2：使用不同的输出格式 =====" << std::endl;

        // 使用默认缩进的YAML输出
        std::string pretty_yaml = config.dump(); // 默认缩进为2
        std::cout << "美观的YAML格式（缩进=2）:\n" << pretty_yaml << std::endl;

        // 使用自定义缩进的JSON输出
        std::string pretty_json = config.dump(4, true); // 缩进为4，输出为JSON
        std::cout << "\n美观的JSON格式（缩进=4）:\n" << pretty_json << std::endl;

        // 保存到文件
        std::ofstream out_file2("config_pretty.json");
        if (out_file2.is_open()) {
            out_file2 << pretty_json;
            out_file2.close();
            std::cout << "已将美观的JSON保存到 config_pretty.json" << std::endl;
        }

        // ===== 方式3：从JSON创建和YAML::Node互操作 =====
        std::cout << "\n\n===== 方式3：从JSON创建和YAML::Node转换 =====" << std::endl;

        // 从JSON创建YamJSON对象
        yamjson::YamJSON config2 = yamjson::YamJSON::from_json(json_data);

        // 修改一些值
        config2["new_setting"] = "added from json";

        // 转换为YAML::Node
        YAML::Node yaml_node = config2.to_yaml_node();
        std::cout << "成功转换为YAML::Node对象" << std::endl;

        // 从YAML::Node创建新的YamJSON对象
        yamjson::YamJSON config3 = yamjson::YamJSON::from_yaml(yaml_node);
        std::cout << "从YAML::Node创建的对象:" << std::endl;
        std::cout << config3.dump() << std::endl;

        // ===== 方式4：文件操作 =====
        std::cout << "\n\n===== 方式4：文件操作 =====" << std::endl;

        // 先保存配置到文件
        config.save_to("temp_config.yaml");
        std::cout << "配置已保存到临时文件 temp_config.yaml" << std::endl;

        // 从文件加载
        yamjson::YamJSON loaded_config = yamjson::YamJSON::load("temp_config.yaml");
        std::cout << "从文件加载配置成功" << std::endl;

        // 修改后保存回原文件
        loaded_config["server"]["host"] = "0.0.0.0";
        loaded_config.save(); // 保存到原文件
        std::cout << "修改后的配置已保存回原文件" << std::endl;

        std::cout << "\n\n===== YamJSON 演示完成 =====\n" << std::endl;
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "错误：" << e.what() << std::endl;
        return 1;
    }
}
