import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../config/app_config.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  bool _isConnected = false;
  String? _currentWsUrl; // 存储当前使用的WebSocket URL
  
  // 回调函数
  final Function(dynamic) onMessageReceived;
  final Function(bool) onConnectionStatusChanged;
  final Function(String) onError;
  
  WebSocketService({
    required this.onMessageReceived,
    required this.onConnectionStatusChanged,
    required this.onError,
  });

  bool get isConnected => _isConnected;
  int get reconnectAttempts => _reconnectAttempts;
  int get maxReconnectAttempts => _maxReconnectAttempts;

  // 使用指数退避算法计算等待时间（毫秒）
  int _getNextReconnectDelay() {
    // 基础等待时间：1秒，最大等待时间：30秒
    int baseDelay = 1000;
    int maxDelay = 30000;
    
    // 2的重连次数次方 * 基础时间，但不超过最大时间
    int delay = baseDelay * (1 << _reconnectAttempts);
    return delay < maxDelay ? delay : maxDelay;
  }
  
  void connect(String userId, [String? customWsUrl]) {
    if (_isConnecting) return;
    
    _isConnecting = true;
    try {
      // 使用自定义URL或从配置中获取WebSocket URL并添加查询参数
      String wsUrlBase;
      if (customWsUrl != null && customWsUrl.isNotEmpty) {
        wsUrlBase = 'ws://$customWsUrl';
        _currentWsUrl = customWsUrl; // 保存当前URL用于重连
      } else {
        wsUrlBase = AppConfig.webSocketUrl;
        _currentWsUrl = null; // 使用默认配置
      }
      
      final wsUrl = '$wsUrlBase?userId=$userId';
      final uri = Uri.parse(wsUrl);
      
      debugPrint('正在连接到WebSocket服务器: $wsUrl');
      
      // 创建WebSocket连接
      _channel = WebSocketChannel.connect(uri);
      
      // 监听消息
      _channel!.stream.listen(
        (message) {
          // 连接成功，重置重连次数
          _isConnected = true;
          _reconnectAttempts = 0;
          onConnectionStatusChanged(_isConnected);
          onMessageReceived(message);
        }, 
        onError: (error) {
          debugPrint('WebSocket错误: $error');
          _isConnected = false;
          onConnectionStatusChanged(_isConnected);
          onError('连接错误: $error');
          _scheduleReconnect(userId);
        }, 
        onDone: () {
          debugPrint('WebSocket连接关闭');
          _isConnected = false;
          onConnectionStatusChanged(_isConnected);
          _scheduleReconnect(userId);
        }
      );
      
      _isConnected = true;
      onConnectionStatusChanged(_isConnected);
      
    } catch (e) {
      debugPrint('连接WebSocket时发生错误: $e');
      _isConnected = false;
      onConnectionStatusChanged(_isConnected);
      onError('连接错误: $e');
      _scheduleReconnect(userId);
    }
    _isConnecting = false;
  }
  
  void _scheduleReconnect(String userId) {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('达到最大重连次数 ($_maxReconnectAttempts)，不再重连');
      return;
    }
    
    int delay = _getNextReconnectDelay();
    _reconnectAttempts++;
    
    debugPrint('尝试在 $delay 毫秒后重连，当前尝试次数: $_reconnectAttempts');
    
    Future.delayed(Duration(milliseconds: delay), () {
      debugPrint('正在进行第 $_reconnectAttempts 次重连尝试...');
      connect(userId, _currentWsUrl);
    });
  }

  void sendMessage(Message message) {
    if (_channel != null && _isConnected) {
      final messageData = {
        'senderId': message.senderId,
        'receiverId': message.receiverId,
        'content': message.content,
        'type': message.type,
      };
      
      try {
        _channel!.sink.add(jsonEncode(messageData));
        return;
      } catch (e) {
        debugPrint('发送消息错误: $e');
        onError('发送失败: $e');
        throw Exception('发送消息失败');
      }
    } else {
      onError('未连接到服务器');
      throw Exception('未连接到服务器');
    }
  }

  void dispose() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _reconnectAttempts = _maxReconnectAttempts; // 设为最大值，不再重连
  }
}
