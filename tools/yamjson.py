import gdb
import re

ns_pattern = re.compile(r'nlohmann(::json_abi(?P<tags>\w*)(_v(?P<v_major>\d+)_(?P<v_minor>\d+)_(?P<v_patch>\d+))?)?::(?P<n>.+)')
class JsonValuePrinter:
    "Print a json-value"

    def __init__(self, val, is_null=False):
        self.val = val
        self.is_null = is_null

    def to_string(self):
        if self.is_null:
            return "null"
        if self.val.type.strip_typedefs().code == gdb.TYPE_CODE_FLT:
            # 格式化为最多6位小数，但保证至少保留1位小数
            formatted = ("%.6f" % float(self.val))
            # 移除多余的0，但确保至少保留一个小数位
            if '.' in formatted:
                integer_part, decimal_part = formatted.split('.')
                decimal_part = decimal_part.rstrip('0')
                if not decimal_part:
                    decimal_part = '0'  # 至少保留一位小数
                return f"{integer_part}.{decimal_part}"
            return formatted
        return self.val

class YamlDocumentPrinter:
    "Print a yaml document with comments"

    def __init__(self, val):
        self.val = val
        self.doc = val['doc_']
        self.file_path = val['file_path_']
        self.json_data = None
        self.original_yaml = None
        self.yaml_lines = []
        self.yaml_dict = {}

        # 尝试初始化获取JSON数据和原始YAML
        try:
            # 检查doc_是否为智能指针
            if self.doc.type.code == gdb.TYPE_CODE_PTR:
                # 如果是直接指针，直接解引用
                yaml_doc = self.doc.dereference()
            else:
                # 如果是智能指针，需要访问其内部指针
                # 获取shared_ptr内部的原始指针
                raw_ptr = self.doc['_M_ptr']
                if (raw_ptr and raw_ptr != 0):
                    yaml_doc = raw_ptr.dereference()
                else:
                    return

            # 获取json_data_
            self.json_data = yaml_doc['json_data_']

            # 获取原始YAML
            self.original_yaml = yaml_doc['original_yaml_']

            # 解析YAML文本为键值对
            if self.original_yaml:
                yaml_str = str(self.original_yaml).strip('"')
                # 处理转义字符
                yaml_str = yaml_str.replace('\\n', '\n').replace('\\t', '\t').replace('\\"', '"')
                self.yaml_lines = yaml_str.split('\n')

                # 解析YAML行为键值对
                for line in self.yaml_lines:
                    line = line.strip()
                    if line and not line.startswith('#'):  # 跳过注释和空行
                        if ':' in line:
                            parts = line.split(':', 1)
                            if len(parts) == 2:
                                key = parts[0].strip()
                                value = parts[1].strip()
                                self.yaml_dict[key] = value

        except Exception as e:
            print(f"YamlDocumentPrinter初始化错误: {str(e)}")

    def to_string(self):
        # 显示YAML文档的基本信息
        file_path_str = str(self.file_path)
        if file_path_str and file_path_str != '""':
            return f"YAML文档 (文件: {file_path_str})"
        return "YAML文档"

    def children(self):
        result = []
        # 先显示文件路径，key为FilePath
        if str(self.file_path) and str(self.file_path) != '""':
            result.append(("FilePath", self.file_path))
        # 以data为key递归展开json_data
        if self.json_data is not None:
            result.append(("data", self.json_data))
        return result

    def display_hint(self):
        return 'map'  # 告诉VS Code这是一个可展开的映射

class YamlDictPrinter:
    "Print YAML as key-value pairs"

    def __init__(self, yaml_dict):
        self.yaml_dict = yaml_dict

    def to_string(self):
        return f"YAML内容 ({len(self.yaml_dict)} 项)"

    def children(self):
        result = []
        for key, value in self.yaml_dict.items():
            result.append((key, value))
        return result

    def display_hint(self):
        return 'map'

class YamlCommentsPrinter:
    "Print YAML comments"

    def __init__(self, comments):
        self.comments = comments

    def to_string(self):
        return f"注释 ({len(self.comments)} 行)"

    def children(self):
        return self.comments

    def display_hint(self):
        return 'array'

def json_lookup_function(val):
    # 检查是否是nlohmann::yaml::document类型
    try:
        type_name = str(val.type.strip_typedefs().name)
        if "nlohmann::yaml::document" in type_name:
            return YamlDocumentPrinter(val)
    except:
        pass

    # 原有的JSON处理逻辑
    if m := ns_pattern.fullmatch(str(val.type.strip_typedefs().name)):
        name = m.group('n')
        if name and name.startswith('basic_json<') and name.endswith('>'):
            m_data = val['m_data']
            m_type = m_data['m_type']
            m = ns_pattern.fullmatch(str(m_type))
            t = m.group('n')
            prefix = 'detail::value_t::'
            if t and t.startswith(prefix):
                # 检查是否为null类型
                if t == prefix + 'null':
                    return JsonValuePrinter(m_type, True)
                try:
                    union_val = m_data['m_value'][t.replace(prefix, '', 1)]
                    if union_val.type.code == gdb.TYPE_CODE_PTR:
                        return gdb.default_visualizer(union_val.dereference())
                    else:
                        return JsonValuePrinter(union_val)
                except Exception:
                    return JsonValuePrinter(m_type)

gdb.pretty_printers.append(json_lookup_function)