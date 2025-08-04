import 'package:flutter/material.dart';
import 'chat_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _receiverIdController = TextEditingController();
  final TextEditingController _wsUrlController = TextEditingController(text: "localhost:10002/ws");

  @override
  void dispose() {
    _userIdController.dispose();
    _receiverIdController.dispose();
    _wsUrlController.dispose();
    super.dispose();
  }

  void _navigateToChatPage() {
    final userId = _userIdController.text.trim();
    final receiverId = _receiverIdController.text.trim();
    final wsUrl = _wsUrlController.text.trim();
    
    if (userId.isNotEmpty && receiverId.isNotEmpty && wsUrl.isNotEmpty) {
      // 检查ID是否都是数字
      if (_isNumeric(userId) && _isNumeric(receiverId)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              userId: userId,
              receiverId: receiverId,
              wsUrl: wsUrl,
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
        const SnackBar(content: Text('请输入所有必填字段')),
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
              TextField(
                controller: _wsUrlController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'WebSocket地址',
                  hintText: '例如: 192.168.1.1:8080/chat',
                ),
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
