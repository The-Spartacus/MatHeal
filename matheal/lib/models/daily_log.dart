// lib/models/daily_log.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the user's emotional state for the day.
enum MoodType {
  happy,
  calm,
  energetic,
  sad,
  anxious,
  tired,
  irritable,
}

/// ADD THIS EXTENSION to add properties like names and emojis to your enum
extension MoodTypeExtension on MoodType {
  String get emoji {
    switch (this) {
      case MoodType.happy: return '😄';
      case MoodType.calm: return '😌';
      case MoodType.energetic: return '⚡️';
      case MoodType.sad: return '😢';
      case MoodType.anxious: return '😟';
      case MoodType.tired: return '😴';
      case MoodType.irritable: return '😠';
    }
  }

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }
}

/// Represents common symptoms a user can log.
enum SymptomType {
  nausea,
  fatigue,
  headache,
  backPain,
  cramping,
  swelling,
  other, // For custom symptoms
}

/// ADD THIS EXTENSION to get a user-friendly name for your symptom enum
extension SymptomTypeExtension on SymptomType {
  String get displayName {
    switch (this) {
      case SymptomType.backPain: return 'Back Pain';
      // Add other cases as needed for two-word names
      default: return name[0].toUpperCase() + name.substring(1);
    }
  }
}

/// Represents a single symptom logged by the user, including its severity.
class LoggedSymptom {
  final SymptomType type;
  final int severity; // A rating from 1 (mild) to 5 (severe)
  final String? customName; // Used only if type is 'other'

  LoggedSymptom({
    required this.type,
    required this.severity,
    this.customName,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'severity': severity,
      'customName': customName,
    };
  }

  factory LoggedSymptom.fromMap(Map<String, dynamic> map) {
    return LoggedSymptom(
      type: SymptomType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => SymptomType.other,
      ),
      severity: map['severity'] ?? 0,
      customName: map['customName'],
    );
  }
}

/// Represents the main log entry for a specific user on a specific day.
class DailyLog {
  final String? id;
  final String userId;
  final DateTime date;
  final MoodType mood;
  final List<LoggedSymptom> symptoms;
  final String? notes;

  DailyLog({
    this.id,
    required this.userId,
    required this.date,
    required this.mood,
    required this.symptoms,
    this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'mood': mood.toString(),
      'symptoms': symptoms.map((symptom) => symptom.toMap()).toList(),
      'notes': notes,
    };
  }

  factory DailyLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return DailyLog(
      id: doc.id,
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
      mood: MoodType.values.firstWhere(
        (e) => e.toString() == data['mood'],
        orElse: () => MoodType.calm,
      ),
      symptoms: (data['symptoms'] as List<dynamic>)
          .map((symptomData) => LoggedSymptom.fromMap(symptomData))
          .toList(),
      notes: data['notes'],
    );
  }
}