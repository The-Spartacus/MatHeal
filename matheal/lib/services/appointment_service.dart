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
    return _db
        .where("doctorId", isEqualTo: doctorId)
        .orderBy("dateTime")
        .snapshots();
  }

  Stream<QuerySnapshot> getConfirmedAppointmentsStream(String userId) {
    return _db
        .where("userId", isEqualTo: userId)
        .where('status', isEqualTo: 'confirmed')
        .where('isRead', isEqualTo: false) // ✅ Only fetch unread notifications
        .snapshots();
  }
  Future<void> markAppointmentsAsRead(String userId) async {
    // Get all confirmed but unread appointments for the user
    final querySnapshot = await _db
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'confirmed')
        .where('isRead', isEqualTo: false)
        .get();

    // Create a batch write to update all documents at once, which is very efficient.
    final batch = _db.firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
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
