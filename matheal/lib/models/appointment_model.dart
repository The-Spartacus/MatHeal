import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String userId;
  final String doctorId;
  final DateTime dateTime;
  final String notes;
  final String status; // pending, confirmed, cancelled
  final bool isRead; // ✅ ADDED: To track if the notification has been seen

  Appointment({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.dateTime,
    this.notes = "",
    this.status = "pending",
    this.isRead = false, // ✅ Default to false
  });

  factory Appointment.fromFirestore(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      userId: data['userId'] ?? "",
      doctorId: data['doctorId'] ?? "",
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      notes: data['notes'] ?? "",
      status: data['status'] ?? "pending",
      isRead: data['isRead'] ?? false, // ✅ Read from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'doctorId': doctorId,
      'dateTime': Timestamp.fromDate(dateTime),
      'notes': notes,
      'status': status,
      'isRead': isRead, // ✅ Save to Firestore
    };
  }
}

