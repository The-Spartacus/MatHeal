import 'package:cloud_firestore/cloud_firestore.dart';

enum MedicineType { pill, syrup, injection, other }

class MedicineModel {
  final String? id;
  final String userId;
  final String name;
  final String dosage; // e.g., "1 pill", "5 ml"
  final MedicineType type;
  final List<String> frequency; // e.g., ["Daily"], ["Monday", "Wednesday"]
  final List<String> reminderTimes; // e.g., ["08:00", "20:00"]
  final DateTime startDate;
  final DateTime? endDate;
  final String notes;

  MedicineModel({
    this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.type,
    required this.frequency,
    required this.reminderTimes,
    required this.startDate,
    this.endDate,
    this.notes = '',
  });

  factory MedicineModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicineModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      dosage: data['dosage'] ?? '',
      type: MedicineType.values.firstWhere(
          (e) => e.toString() == data['type'],
          orElse: () => MedicineType.other),
      frequency: List<String>.from(data['frequency'] ?? []),
      reminderTimes: List<String>.from(data['reminderTimes'] ?? []),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'dosage': dosage,
      'type': type.toString(),
      'frequency': frequency,
      'reminderTimes': reminderTimes,
      'startDate': startDate,
      'endDate': endDate,
      'notes': notes,
    };
  }

  // Add this copyWith method to your model class
  MedicineModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? dosage,
    MedicineType? type,
    List<String>? frequency,
    List<String>? reminderTimes,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) {
    return MedicineModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
    );
  }
}

/// ---------------- CONSUMED MEDICINE ----------------
class ConsumedMedicine {
  final String? id;
  final String uid;
  final String reminderId;
  final String name;
  final DateTime consumedAt;

  ConsumedMedicine({
    this.id,
    required this.uid,
    required this.reminderId,
    required this.name,
    required this.consumedAt,
  });

  factory ConsumedMedicine.fromFirestore(Map<String, dynamic> data, String id) {
    return ConsumedMedicine(
      id: id,
      uid: data['uid'] ?? '',
      reminderId: data['reminderId'] ?? '',
      // vvvvvvvvvv THE FIX IS APPLIED HERE vvvvvvvvvv
      // This now checks for 'name' and falls back to 'medicineName' for compatibility.
      name: data['name'] ?? data['medicineName'] ?? '',
      // ^^^^^^^^^^ THE FIX IS APPLIED HERE ^^^^^^^^^^
      consumedAt: (data['consumedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'reminderId': reminderId,
      'name': name,
      'consumedAt': consumedAt,
    };
  }
}