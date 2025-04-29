#!/bin/bash
# testing.sh - 测试脚本生成相关函数

# 导入必要的模块
source "$(dirname "${BASH_SOURCE[0]}")/paths.sh"

# 函数: 创建测试脚本
create_test_script() {
    local type=$1
    local script_file="$DIST_DIR/test_yamjson.sh"

    log_info "创建测试脚本: ${script_file}..."

    echo "#!/bin/bash" > "$script_file"
    echo "# yamjson 测试脚本 - 简单测试生成的库是否正常工作" >> "$script_file"
    echo "" >> "$script_file"

    case $type in
        single)
            echo "echo \"测试单头文件版本...\"" >> "$script_file"
            echo "echo '#define YAMJSON_IMPLEMENTATION' > test.cpp" >> "$script_file"
            echo "echo '#include \"include/yamjson.hpp\"' >> test.cpp" >> "$script_file"
            echo "echo 'int main() {' >> test.cpp" >> "$script_file"
            echo "echo '    yamjson::YamJSON y;' >> test.cpp" >> "$script_file"
            echo "echo '    y.loadYaml(\"key: value\");' >> test.cpp" >> "$script_file"
            echo "echo '    std::cout << \"测试成功: \" << y.toJSON() << std::endl;' >> test.cpp" >> "$script_file"
            echo "echo '    return 0;' >> test.cpp" >> "$script_file"
            echo "echo '}' >> test.cpp" >> "$script_file"
            echo "g++ -std=c++11 test.cpp -o test_yamjson -I." >> "$script_file"
            echo "./test_yamjson" >> "$script_file"
            echo "rm test.cpp test_yamjson" >> "$script_file"
            ;;
        static)
            echo "echo \"测试静态库版本（使用合并头文件）...\"" >> "$script_file"
            echo "echo '#include \"include/yamjson_lib.h\"' > test.cpp" >> "$script_file"
            echo "echo 'int main() {' >> test.cpp" >> "$script_file"
            echo "echo '    yamjson::YamJSON y;' >> test.cpp" >> "$script_file"
            echo "echo '    y.loadYaml(\"key: value\");' >> test.cpp" >> "$script_file"
            echo "echo '    std::cout << \"测试成功: \" << y.toJSON() << std::endl;' >> test.cpp" >> "$script_file"
            echo "echo '    return 0;' >> test.cpp" >> "$script_file"
            echo "echo '}' >> test.cpp" >> "$script_file"
            echo "g++ -std=c++11 test.cpp -o test_yamjson -I. -Llib -lyamjson -lyaml" >> "$script_file"
            echo "LD_LIBRARY_PATH=./lib ./test_yamjson" >> "$script_file"
            echo "rm test.cpp test_yamjson" >> "$script_file"
            ;;
        static-debug)
            echo "echo \"测试调试版静态库（使用合并头文件）...\"" >> "$script_file"
            echo "echo '#include \"include/yamjson_lib.h\"' > test.cpp" >> "$script_file"
            echo "echo 'int main() {' >> test.cpp" >> "$script_file"
            echo "echo '    yamjson::YamJSON y;' >> test.cpp" >> "$script_file"
            echo "echo '    y.loadYaml(\"key: value\");' >> test.cpp" >> "$script_file"
            echo "echo '    std::cout << \"测试成功: \" << y.toJSON() << std::endl;' >> test.cpp" >> "$script_file"
            echo "echo '    return 0;' >> test.cpp" >> "$script_file"
            echo "echo '}' >> test.cpp" >> "$script_file"
            echo "g++ -std=c++11 -g test.cpp -o test_yamjson -I. -Llib -lyamjson-debug -lyaml-debug" >> "$script_file"
            echo "LD_LIBRARY_PATH=./lib ./test_yamjson" >> "$script_file"
            echo "rm test.cpp test_yamjson" >> "$script_file"
            ;;
        shared)
            echo "echo \"测试动态库版本（使用合并头文件）...\"" >> "$script_file"
            echo "echo '#include \"include/yamjson_lib.h\"' > test.cpp" >> "$script_file"
            echo "echo 'int main() {' >> test.cpp" >> "$script_file"
            echo "echo '    yamjson::YamJSON y;' >> test.cpp" >> "$script_file"
            echo "echo '    y.loadYaml(\"key: value\");' >> test.cpp" >> "$script_file"
            echo "echo '    std::cout << \"测试成功: \" << y.toJSON() << std::endl;' >> test.cpp" >> "$script_file"
            echo "echo '    return 0;' >> test.cpp" >> "$script_file"
            echo "echo '}' >> test.cpp" >> "$script_file"
            echo "g++ -std=c++11 test.cpp -o test_yamjson -I. -Llib -lyamjson -lyaml" >> "$script_file"
            echo "LD_LIBRARY_PATH=./lib ./test_yamjson" >> "$script_file"
            echo "rm test.cpp test_yamjson" >> "$script_file"
            ;;
        shared-debug)
            echo "echo \"测试调试版动态库（使用合并头文件）...\"" >> "$script_file"
            echo "echo '#include \"include/yamjson_lib.h\"' > test.cpp" >> "$script_file"
            echo "echo 'int main() {' >> test.cpp" >> "$script_file"
            echo "echo '    yamjson::YamJSON y;' >> test.cpp" >> "$script_file"
            echo "echo '    y.loadYaml(\"key: value\");' >> test.cpp" >> "$script_file"
            echo "echo '    std::cout << \"测试成功: \" << y.toJSON() << std::endl;' >> test.cpp" >> "$script_file"
            echo "echo '    return 0;' >> test.cpp" >> "$script_file"
            echo "echo '}' >> test.cpp" >> "$script_file"
            echo "g++ -std=c++11 -g test.cpp -o test_yamjson -I. -Llib -lyamjson-debug -lyaml-debug" >> "$script_file"
            echo "LD_LIBRARY_PATH=./lib ./test_yamjson" >> "$script_file"
            echo "rm test.cpp test_yamjson" >> "$script_file"
            ;;
    esac

    chmod +x "$script_file"
    log_success "测试脚本已创建: $script_file"
}