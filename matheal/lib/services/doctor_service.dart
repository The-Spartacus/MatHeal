// lib/services/doctor_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';

class DoctorService {
  final _db = FirebaseFirestore.instance;

  Future<List<Doctor>> getAllDoctors() async {
    final snapshot = await _db.collection("doctors").get();
    return snapshot.docs.map((doc) => Doctor.fromFirestore(doc.data(), doc.id)).toList();
  }

  Future<Doctor?> getDoctorById(String doctorId) async {
    final doc = await _db.collection("doctors").doc(doctorId).get();
    if (!doc.exists) return null;
    return Doctor.fromFirestore(doc.data()!, doc.id);
  }

  // New method to create a doctor document
  Future<void> createDoctor(Doctor doctor) async {
    final docRef = _db.collection("doctors").doc(doctor.id);
    await docRef.set(doctor.toFirestore());
  }
}