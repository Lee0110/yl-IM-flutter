import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'config/app_config.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '聊天应用',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _receiverIdController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    _receiverIdController.dispose();
    super.dispose();
  }

  void _navigateToChatPage() {
    final userId = _userIdController.text.trim();
    final receiverId = _receiverIdController.text.trim();
    
    if (userId.isNotEmpty && receiverId.isNotEmpty) {
      // 检查是否都是数字
      if (_isNumeric(userId) && _isNumeric(receiverId)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              userId: userId,
              receiverId: receiverId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用户ID和接收者ID必须是数字')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入用户ID和接收者ID')),
      );
    }
  }
  
  // 检查字符串是否只包含数字
  bool _isNumeric(String str) {
    return int.tryParse(str) != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('登录'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '用户ID',
                  hintText: '请输入您的ID (仅数字)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _receiverIdController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '接收者ID',
                  hintText: '请输入接收者的ID (仅数字)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateToChatPage,
                child: const Text('开始聊天'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Message {
  final String content;
  final bool isMine;
  final int senderId;
  final int receiverId;

  Message({
    required this.content, 
    required this.isMine, 
    required this.senderId, 
    required this.receiverId
  });
}

class ChatPage extends StatefulWidget {
  final String userId;
  final String receiverId;

  const ChatPage({
    super.key, 
    required this.userId, 
    required this.receiverId
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  
  // 定义连接状态
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  // 使用指数退避算法计算等待时间（毫秒）
  int _getNextReconnectDelay() {
    // 基础等待时间：1秒，最大等待时间：30秒
    int baseDelay = 1000;
    int maxDelay = 30000;
    
    // 2的重连次数次方 * 基础时间，但不超过最大时间
    int delay = baseDelay * (1 << _reconnectAttempts);
    return delay < maxDelay ? delay : maxDelay;
  }
  
  void _connectToWebSocket() {
    if (_isConnecting) return;
    
    _isConnecting = true;
    try {
      // 从配置中获取WebSocket URL并添加查询参数
      final wsUrl = '${AppConfig.webSocketUrl}?userId=${widget.userId}';
      final uri = Uri.parse(wsUrl);
      
      print('正在连接到WebSocket服务器: $wsUrl');
      
      // 创建WebSocket连接
      _channel = WebSocketChannel.connect(uri);
      
      // 监听消息
      _channel!.stream.listen(
        (message) {
          // 连接成功，重置重连次数
          _isConnected = true;
          _reconnectAttempts = 0;
          _handleIncomingMessage(message);
        }, 
        onError: (error) {
          print('WebSocket错误: $error');
          _isConnected = false;
          _scheduleReconnect();
        }, 
        onDone: () {
          print('WebSocket连接关闭');
          _isConnected = false;
          _scheduleReconnect();
        }
      );
      
      setState(() {
        // 更新UI显示连接状态
        _isConnected = true;
      });
      
    } catch (e) {
      print('连接WebSocket时发生错误: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
    _isConnecting = false;
  }
  
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('达到最大重连次数 ($_maxReconnectAttempts)，不再重连');
      return;
    }
    
    int delay = _getNextReconnectDelay();
    _reconnectAttempts++;
    
    print('尝试在 $delay 毫秒后重连，当前尝试次数: $_reconnectAttempts');
    
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        print('正在进行第 $_reconnectAttempts 次重连尝试...');
        _connectToWebSocket();
      }
    });
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (data is Map<String, dynamic> && 
          data.containsKey('content') && 
          data.containsKey('senderId') && 
          data.containsKey('receiverId')) {
        // 获取消息中的发送者ID和接收者ID
        final int msgSenderId = data['senderId'] is String 
            ? int.parse(data['senderId']) 
            : data['senderId'];
        final int msgReceiverId = data['receiverId'] is String 
            ? int.parse(data['receiverId']) 
            : data['receiverId'];
        
        // 将当前用户ID转换为整数，用于比较
        final int currentUserId = int.parse(widget.userId);
        
        setState(() {
          _messages.add(
            Message(
              content: data['content'],
              senderId: msgSenderId,
              receiverId: msgReceiverId,
              isMine: msgSenderId == currentUserId,
            ),
          );
        });
      }
    } catch (e) {
      print('处理消息时发生错误: $e');
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      // 将字符串ID转换为整数ID
      final int senderId = int.parse(widget.userId);
      final int receiverId = int.parse(widget.receiverId);
      final String content = _messageController.text.trim();
      
      final message = {
        'senderId': senderId, // 发送整数类型
        'receiverId': receiverId, // 发送整数类型
        'content': content,
      };
      
      // 检查连接状态
      if (_channel != null && _isConnected) {
        try {
          _channel!.sink.add(jsonEncode(message));
        } catch (e) {
          print('发送消息错误: $e');
          _showSnackBar('发送失败，正在尝试重连...');
          _scheduleReconnect();
          return;
        }
      } else {
        _showSnackBar('未连接到服务器，正在尝试重连...');
        _connectToWebSocket();
        return;
      }
      
      setState(() {
        _messages.add(
          Message(
            content: content,
            senderId: senderId,
            receiverId: receiverId,
            isMine: true,
          ),
        );
        _messageController.clear();
      });
    }
  }
  
  // 显示提示消息
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    // 关闭WebSocket连接
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    // 设置状态，防止dispose后再尝试重连
    _isConnected = false;
    _reconnectAttempts = _maxReconnectAttempts; // 设为最大值，不再重连
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('我(${widget.userId}) → 对方(${widget.receiverId})'),
        // 显示当前环境
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            color: AppConfig.environment == Environment.dev ? Colors.amber[700] : Colors.green[700],
            alignment: Alignment.center,
            child: Text(
              AppConfig.environment == Environment.dev ? '开发环境' : '生产环境',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
        actions: [
          // 添加连接状态指示器
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isConnected 
              ? const Icon(Icons.wifi, color: Colors.green)
              : const Icon(Icons.wifi_off, color: Colors.red),
          ),
        ],
      ),
      body: Column(
        children: [
          // 显示重连状态的条
          if (!_isConnected)
            Container(
              color: Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16.0, 
                    height: 16.0, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    '正在尝试重新连接... (${_reconnectAttempts}/${_maxReconnectAttempts})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: message.isMine ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 显示发送者ID
            Text(
              message.isMine ? '我(ID: ${message.senderId})' : '对方(ID: ${message.senderId})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(message.content),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            onPressed: _sendMessage,
            mini: true,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
