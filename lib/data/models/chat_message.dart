import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String senderId;

  @HiveField(2)
  String senderName;

  @HiveField(3)
  String content;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  MessageType type;

  @HiveField(6)
  bool isFromCurrentUser;

  @HiveField(7)
  MessageStatus status;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.isFromCurrentUser = false,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values.firstWhere((e) => e.toString() == 'MessageType.${json['type']}', orElse: () => MessageType.text),
      isFromCurrentUser: json['isFromCurrentUser'] ?? false,
      status: MessageStatus.values.firstWhere((e) => e.toString() == 'MessageStatus.${json['status']}', orElse: () => MessageStatus.sent),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'isFromCurrentUser': isFromCurrentUser,
      'status': status.toString().split('.').last,
    };
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, content: $content, timestamp: $timestamp)';
  }
}

@HiveType(typeId: 1)
enum MessageType {
  @HiveField(0)
  text,
  @HiveField(1)
  image,
  @HiveField(2)
  file,
  @HiveField(3)
  system,
}

@HiveType(typeId: 2)
enum MessageStatus {
  @HiveField(0)
  sending,
  @HiveField(1)
  sent,
  @HiveField(2)
  delivered,
  @HiveField(3)
  read,
  @HiveField(4)
  failed,
}
