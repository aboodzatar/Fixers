import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String? id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;

  ChatMessage({
    this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
