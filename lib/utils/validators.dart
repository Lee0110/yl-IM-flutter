class Validators {
  /// 检查字符串是否为数字
  static bool isNumeric(String value) {
    return int.tryParse(value) != null;
  }
  
  /// 检查字符串是否为空或只包含空格
  static bool isEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }
  
  /// 检查字符串长度是否在指定范围内
  static bool isLengthValid(String value, int minLength, int maxLength) {
    return value.length >= minLength && value.length <= maxLength;
  }
  
  /// 检查电子邮件格式是否有效
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(email);
  }
}
