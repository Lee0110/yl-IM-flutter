enum Environment {
  dev,
  prod,
}

class AppConfig {
  // 当前环境
  static const Environment environment = Environment.dev;
  
  // WebSocket基础URL
  static String get webSocketBaseUrl {
    switch (environment) {
      case Environment.dev:
        return 'ws://localhost:10002';
      case Environment.prod:
        return 'wss://chat.yourdomain.com'; // 替换为您的生产环境WebSocket地址
    }
  }
  
  // WebSocket完整URL（包含路径）
  static String get webSocketUrl {
    return '$webSocketBaseUrl/ws';
  }
  
  // 切换环境的函数（仅供参考，实际使用时可能需要修改构建配置）
  static String getWebSocketUrl(Environment env) {
    switch (env) {
      case Environment.dev:
        return 'ws://localhost:10002/ws';
      case Environment.prod:
        return 'wss://chat.yourdomain.com/ws'; // 替换为您的生产环境WebSocket地址
    }
  }
}
