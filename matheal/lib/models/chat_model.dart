import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String? id;
  final String userId; // The ID of the user who the conversation belongs to
  final String text;
  final bool isUser; // True if the message is from the human user, false if from the bot
  final DateTime timestamp;
  final bool isError;

  ChatMessageModel({
    this.id,
    required this.userId,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  // Helper to create a copy with some updated fields
  ChatMessageModel copyWith({
    String? id,
    String? userId,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isError,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }

  // Factory to create a message from a Firestore document
  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      isUser: data['isUser'] ?? true,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isError: data['isError'] ?? false,
    );
  }

  // Method to convert a message object to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'isError': isError,
    };
  }
}

