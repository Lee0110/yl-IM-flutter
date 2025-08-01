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
