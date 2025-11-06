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
  final String wsUrl;

  const ChatPage({
    super.key, 
    required this.userId, 
    required this.receiverId,
    required this.wsUrl
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
    
    _webSocketService.connect(widget.userId, widget.wsUrl);
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      if (data is Map<String, dynamic> && data.containsKey('content') && data.containsKey('senderId')) {
        // 发送者/接收者
        final int currentUserId = int.parse(widget.userId);
        final int msgSenderId = data['senderId'] is String
            ? int.tryParse(data['senderId']) ?? -1
            : (data['senderId'] ?? -1);
        // receiverId 可能缺失（系统消息），缺失则回退为当前用户ID
        final int msgReceiverId = data.containsKey('receiverId')
            ? (data['receiverId'] is String
                ? int.tryParse(data['receiverId']) ?? currentUserId
                : (data['receiverId'] ?? currentUserId))
            : currentUserId;

        // 类型与内容
        final String msgType = (data['type'] ?? 'TEXT').toString();
        final String content = (data['content'] ?? '').toString();

        // 判定是否为后端主动断开前的系统消息（放宽匹配）
        final bool isSystemClose =
            msgType.toUpperCase() == 'SYSTEM' &&
            msgSenderId == -1 &&
            (content.contains('自动关闭') || content.contains('长时间无响应'));

        if (isSystemClose) {
          _webSocketService.disableReconnect();
          _showSnackBar('连接因长时间无响应被服务器关闭，将不再自动重连');
        }

        setState(() {
          _messages.add(
            Message(
              content: content,
              senderId: msgSenderId,
              receiverId: msgReceiverId,
              isMine: msgSenderId == currentUserId,
              type: msgType,
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
  // 明确写死 TEXT（与后端对齐）
  type: 'TEXT',
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
          if (_webSocketService.reconnectDisabled) {
            _showSnackBar('连接已被服务器关闭（空闲超时），请退出重进会话');
          } else {
            _showSnackBar('未连接到服务器，正在尝试重连...');
            _webSocketService.connect(widget.userId);
          }
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
          // 服务器主动关闭后的固定提示条（不再自动重连）
          if (!isConnected && _webSocketService.reconnectDisabled)
            Container(
              width: double.infinity,
              color: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
              child: Row(
                children: const [
                  Icon(Icons.block, color: Colors.white, size: 16),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      '连接因长时间无响应被服务器关闭，已停止自动重连。请退出并重新进入会话。',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          // 显示重连状态的条
          if (!isConnected && !_webSocketService.reconnectDisabled)
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
