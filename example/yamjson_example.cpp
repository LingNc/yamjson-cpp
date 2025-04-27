#include <iostream>
#include <fstream>
#include <string>
#include "../include/yamjson.h"

/**
 * YAML-JSON转换演示
 * 本例展示如何在nlohmann::json库中直接处理YAML格式数据
 * 包括保留注释和不保留注释两种方式
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

        std::cout << "===== YAML <-> JSON 转换示例 =====" << std::endl;
        std::cout << "\n原始YAML内容：\n" << yaml_str << std::endl;

        // ====== 方式1：保留注释的YAML处理 ======
        std::cout << "\n\n===== 方式1：保留YAML注释 =====" << std::endl;

        // 创建一个保留注释的YAML文档
        nlohmann::yaml::document doc(yaml_str);

        // 获取解析后的JSON
        nlohmann::json& config = doc.get_json();

        std::cout << "解析后的JSON格式:\n" << config.dump(2) << std::endl;

        // 修改JSON数据
        config["server"]["port"] = 9000;
        config["server"]["debug"] = false;

        // 使用路径更新API修改数据
        doc.update({"storage", "type"}, "remote");
        doc.update({"storage", "options"}, nlohmann::json::array({"cache", "compress", "encrypt"}));

        // 转换回YAML（保留注释）
        std::string updated_yaml = doc.dump();

        std::cout << "\n修改后的YAML（保留了注释）:\n" << updated_yaml << std::endl;

        // 保存到文件
        std::ofstream out_file("config_with_comments.yaml");
        if (out_file.is_open()) {
            out_file << updated_yaml;
            out_file.close();
            std::cout << "已将带注释的配置保存到 config_with_comments.yaml" << std::endl;
        }

        // ====== 方式2：常规YAML-JSON转换（不保留注释）======
        std::cout << "\n\n===== 方式2：常规YAML-JSON转换（不保留注释） =====" << std::endl;

        // 从YAML字符串解析为JSON
        nlohmann::json simple_config;
        nlohmann::from_yaml(yaml_str, simple_config);

        std::cout << "解析后的JSON格式:\n" << simple_config.dump(2) << std::endl;

        // 修改JSON数据
        simple_config["server"]["port"] = 9000;
        simple_config["server"]["debug"] = false;
        simple_config["storage"]["type"] = "remote";
        simple_config["storage"]["options"] = {"cache", "compress", "encrypt"};

        // 转换回YAML（不含注释）
        std::string yaml_no_comments = nlohmann::to_yaml(simple_config);

        std::cout << "\n修改后的YAML（不含注释）:\n" << yaml_no_comments << std::endl;

        // 保存到文件
        std::ofstream out_file2("config_without_comments.yaml");
        if (out_file2.is_open()) {
            out_file2 << yaml_no_comments;
            out_file2.close();
            std::cout << "已将无注释的配置保存到 config_without_comments.yaml" << std::endl;
        }

        std::cout << "\n\n===== YAML与JSON互转示例完成 =====\n" << std::endl;
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "错误：" << e.what() << std::endl;
        return 1;
    }
}
