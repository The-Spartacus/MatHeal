import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- USER OPERATIONS ----------------
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toFirestore());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromFirestore(doc.data()!);
    }
    return null;
  }

  // ---------------- DOCTOR OPERATIONS ----------------
  Future<List<UserModel>> getAllDoctors() async {
    final snapshot =
        await _db.collection("users").where("role", isEqualTo: "doctor").get();

    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data()!))
        .toList();
  }

  Future<UserModel?> getDoctorById(String doctorId) async {
    final doc = await _db.collection("users").doc(doctorId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc.data()!);
  }

  /// Updates the DoctorProfile sub-collection within a user document.
  Future<void> updateDoctorProfile(String uid, DoctorProfile profile) async {
    await _db.collection('users').doc(uid).update({
      'doctorProfile': profile.toFirestore(),
    });
  }

  // ---------------- PROFILE OPERATIONS (for regular users) ----------------
  Future<void> createOrUpdateProfile(UserProfile profile) async {
    await _db.collection('profiles').doc(profile.uid).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );
  }

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _db.collection('profiles').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromFirestore(doc.data()!);
    }
    return null;
  }

  // ---------------- REMINDER OPERATIONS ----------------
  Future<String> addReminder(ReminderModel reminder) async {
    final docRef =
        await _db.collection('reminders').add(reminder.toFirestore());
    return docRef.id;
  }

  Future<void> updateReminder(String id, ReminderModel reminder) async {
    await _db.collection('reminders').doc(id).update(reminder.toFirestore());
  }

  Future<void> deleteReminder(String id) async {
    await _db.collection('reminders').doc(id).delete();
  }

  Stream<List<ReminderModel>> getReminders(String uid) {
    return _db
        .collection('reminders')
        .where('uid', isEqualTo: uid)
        .orderBy('time')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReminderModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ---------------- CONSUMED MEDICINES ----------------
  Future<void> addConsumedMedicine(ConsumedMedicine medicine) async {
    await _db.collection('consumed_medicines').add(medicine.toFirestore());
  }

  Stream<List<ConsumedMedicine>> getConsumedMedicines(String uid) {
    return _db
        .collection('consumed_medicines')
        .where('uid', isEqualTo: uid)
        .orderBy('consumedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConsumedMedicine.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
