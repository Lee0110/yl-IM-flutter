class Message {
  final String content;
  final bool isMine;
  final int senderId;
  final int receiverId;
  // 新增：消息类型，后端新增字段，临时写死为 TEXT
  final String type;

  Message({
    required this.content,
    required this.isMine,
    required this.senderId,
    required this.receiverId,
    this.type = 'TEXT',
  });
}
