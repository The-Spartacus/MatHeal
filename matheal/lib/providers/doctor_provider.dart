// lib/providers/doctor_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/doctor_model.dart'; // assuming your Doctor class is saved here

class DoctorProvider extends ChangeNotifier {
  Doctor? _doctor;
  bool _isLoading = false;

  Doctor? get doctor => _doctor;
  bool get isLoading => _isLoading;

  /// Set doctor data
  void setDoctor(Doctor? doctor) {
    _doctor = doctor;
    notifyListeners();
  }

  /// Loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear doctor session (logout, reset)
  void clear() {
    _doctor = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Example: Load doctor data from Firestore
 Future<void> loadDoctorFromFirebase() async {
  setLoading(true);
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('doctors')
        .doc(uid)
        .get();

    if (snap.exists) {
      _doctor = Doctor.fromFirestore(snap.data()!, snap.id);
    }
  } catch (e) {
    debugPrint("Error loading doctor: $e");
  } finally {
    setLoading(false);
  }
}

}
