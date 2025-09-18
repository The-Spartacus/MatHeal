import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final _db = FirebaseFirestore.instance.collection("appointments");

  /// Creates a new appointment with a "pending" status.
  Future<void> createAppointment(Appointment appointment) async {
    await _db.add(appointment.toFirestore());
  }

  /// Gets a real-time stream of appointments for a specific user.
  Stream<QuerySnapshot> getAppointmentsStreamForUser(String userId) {
    return _db.where("userId", isEqualTo: userId).snapshots();
  }

  /// Gets a real-time stream of appointments for a specific doctor.
  Stream<QuerySnapshot> getAppointmentsStreamForDoctor(String doctorId) {
    return _db.where("doctorId", isEqualTo: doctorId).orderBy("dateTime").snapshots();
  }

  /// Updates an appointment's status (e.g., to "confirmed" or "cancelled").
  Future<void> updateAppointmentStatus(String id, String status) async {
    await _db.doc(id).update({"status": status});
  }

  /// Deletes an appointment document (used when a user cancels a pending request).
  Future<void> deleteAppointment(String id) async {
    await _db.doc(id).delete();
  }
}