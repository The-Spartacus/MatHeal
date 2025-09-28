import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single AI-generated diet suggestion session.
class DietChatEntry {
  final String? id;
  final String userId;
  final String prompt;
  final String response;
  final DateTime timestamp;

  DietChatEntry({
    this.id,
    required this.userId,
    required this.prompt,
    required this.response,
    required this.timestamp,
  });

  /// Creates a copy of the instance with updated fields.
  DietChatEntry copyWith({
    String? id,
    String? userId,
    String? prompt,
    String? response,
    DateTime? timestamp,
  }) {
    return DietChatEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      prompt: prompt ?? this.prompt,
      response: response ?? this.response,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Creates an instance from a Firestore document.
  factory DietChatEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DietChatEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      prompt: data['prompt'] ?? '',
      response: data['response'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  /// Converts the instance to a map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'prompt': prompt,
      'response': response,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Represents a user's logged nutritional intake for a single day.
class DailyIntakeRecord {
  final String? id;
  final String userId;
  final DateTime date;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;

  DailyIntakeRecord({
    this.id,
    required this.userId,
    required this.date,
    this.calories = 0,
    this.proteinGrams = 0,
    this.carbsGrams = 0,
    this.fatGrams = 0,
  });

  /// Creates a copy of the instance with updated fields.
  DailyIntakeRecord copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? calories,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
  }) {
    return DailyIntakeRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
    );
  }

  /// Creates an instance from a Firestore document.
  factory DailyIntakeRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyIntakeRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      calories: data['calories'] ?? 0,
      proteinGrams: data['proteinGrams'] ?? 0,
      carbsGrams: data['carbsGrams'] ?? 0,
      fatGrams: data['fatGrams'] ?? 0,
    );
  }

  /// Converts the instance to a map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'calories': calories,
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
    };
  }
}