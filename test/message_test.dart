import 'package:flutter_test/flutter_test.dart';
import 'package:chatappdemo1/models/message.dart';

void main() {
  group('Message Model Tests', () {
    test('Message should have default type of 1 when not specified', () {
      final message = Message(
        content: 'Hello World',
        isMine: true,
        senderId: 1001,
        receiverId: 1002,
      );
      
      expect(message.type, equals(1));
      expect(message.content, equals('Hello World'));
      expect(message.senderId, equals(1001));
      expect(message.receiverId, equals(1002));
    });

    test('Message should accept custom type value', () {
      final systemMessage = Message(
        content: 'System notification',
        isMine: false,
        senderId: 0,
        receiverId: 1001,
        type: 2,
      );
      
      expect(systemMessage.type, equals(2));
      expect(systemMessage.content, equals('System notification'));
    });

    test('Message should handle file type', () {
      final fileMessage = Message(
        content: 'file.pdf',
        isMine: true,
        senderId: 1001,
        receiverId: 1002,
        type: 3,
      );
      
      expect(fileMessage.type, equals(3));
      expect(fileMessage.content, equals('file.pdf'));
    });

    test('Message should maintain all required fields', () {
      final message = Message(
        content: 'Test message',
        isMine: false,
        senderId: 1005,
        receiverId: 1001,
        type: 1,
      );
      
      expect(message.content, equals('Test message'));
      expect(message.isMine, equals(false));
      expect(message.senderId, equals(1005));
      expect(message.receiverId, equals(1001));
      expect(message.type, equals(1));
    });
  });
}
