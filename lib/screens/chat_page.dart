import 'package:flutter/material.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../services/websocket_service.dart';
import '../config/app_config.dart';
import 'dart:convert';

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
  late WebSocketService _webSocketService;
  
  @override
  void initState() {
    super.initState();
    _initWebSocketService();
  }

  void _initWebSocketService() {
    _webSocketService = WebSocketService(
      onMessageReceived: _handleIncomingMessage,
      onConnectionStatusChanged: (isConnected) {
        setState(() {
          // 连接状态改变时更新UI
        });
      },
      onError: (error) {
        _showSnackBar(error);
      },
    );
    
    _webSocketService.connect(widget.userId);
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
      debugPrint('处理消息时发生错误: $e');
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      // 将字符串ID转换为整数ID
      final int senderId = int.parse(widget.userId);
      final int receiverId = int.parse(widget.receiverId);
      final String content = _messageController.text.trim();
      
      final message = Message(
        content: content,
        senderId: senderId,
        receiverId: receiverId,
        isMine: true,
      );
      
      try {
        _webSocketService.sendMessage(message);
        setState(() {
          _messages.add(message);
          _messageController.clear();
        });
      } catch (e) {
        if (_webSocketService.isConnected) {
          _showSnackBar('发送失败，请重试');
        } else {
          _showSnackBar('未连接到服务器，正在尝试重连...');
          _webSocketService.connect(widget.userId);
        }
      }
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
    _webSocketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isConnected = _webSocketService.isConnected;
    final int reconnectAttempts = _webSocketService.reconnectAttempts;
    final int maxReconnectAttempts = _webSocketService.maxReconnectAttempts;
    
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
            child: isConnected 
              ? const Icon(Icons.wifi, color: Colors.green)
              : const Icon(Icons.wifi_off, color: Colors.red),
          ),
        ],
      ),
      body: Column(
        children: [
          // 显示重连状态的条
          if (!isConnected)
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
                    '正在尝试重新连接... ($reconnectAttempts/$maxReconnectAttempts)',
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
                return MessageBubble(message: message);
              },
            ),
          ),
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
