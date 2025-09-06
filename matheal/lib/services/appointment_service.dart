// lib/services/appointment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final _db = FirebaseFirestore.instance;

  Future<void> createAppointment(Appointment appointment) async {
    final doc = _db.collection("appointments").doc();
    await doc.set(appointment.toFirestore());
  }

  Future<List<Appointment>> getAppointmentsForUser(String userId) async {
    final snapshot = await _db
        .collection("appointments")
        .where("userId", isEqualTo: userId)
        .orderBy("dateTime", descending: false)
        .get();
    return snapshot.docs
        .map((doc) => Appointment.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<List<Appointment>> getAppointmentsForDoctor(String doctorId) async {
    final snapshot = await _db
        .collection("appointments")
        .where("doctorId", isEqualTo: doctorId)
        .orderBy("dateTime", descending: false)
        .get();
    return snapshot.docs
        .map((doc) => Appointment.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateAppointmentStatus(String id, String status) async {
    await _db.collection("appointments").doc(id).update({"status": status});
  }
}
