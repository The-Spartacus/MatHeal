import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String userId;
  final String doctorId;
  final DateTime dateTime;
  final String notes;
  final String status; // pending, confirmed, cancelled

  Appointment({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.dateTime,
    this.notes = "",
    this.status = "pending",
  });

  factory Appointment.fromFirestore(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      userId: data['userId'] ?? "",
      doctorId: data['doctorId'] ?? "",
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      notes: data['notes'] ?? "",
      status: data['status'] ?? "pending",
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'doctorId': doctorId,
      'dateTime': Timestamp.fromDate(dateTime),
      'notes': notes,
      'status': status,
    };
  }
}
