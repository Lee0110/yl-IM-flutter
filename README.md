# chatappdemo1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Message Structure

Messages in this application now support a `type` field for better extensibility:

```json
{
    "senderId": 1005,
    "receiverId": 1001,
    "content": "Hello, World!",
    "type": 1
}
```

### Message Types

- `1` - Normal message (default)
- `2` - System message
- `3` - File message
- Custom types can be added as needed

### Usage

When creating a message, you can optionally specify the type:

```dart
// Normal message (type defaults to 1)
final message = Message(
  content: 'Hello',
  senderId: 1001,
  receiverId: 1002,
  isMine: true,
);

// System message
final systemMessage = Message(
  content: 'User joined the chat',
  senderId: 0,
  receiverId: 1001,
  isMine: false,
  type: 2,
);

// File message
final fileMessage = Message(
  content: 'document.pdf',
  senderId: 1001,
  receiverId: 1002,
  isMine: true,
  type: 3,
);
```

