class Message {
  final String content;
  final bool isMine;
  final int senderId;
  final int receiverId;
  final int type; // 消息类型: 1=普通消息, 2=系统消息, 3=文件消息等

  Message({
    required this.content, 
    required this.isMine, 
    required this.senderId, 
    required this.receiverId,
    this.type = 1, // 默认为普通消息
  });
}
