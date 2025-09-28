import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matheal/models/chat_model.dart';
import 'package:matheal/models/diet_model.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/medicine_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ... (all other methods like USER, DOCTOR, RATING operations remain the same) ...

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
        .map((doc) => UserModel.fromFirestore(doc.data()))
        .toList();
  }

  Future<UserModel?> getDoctorById(String doctorId) async {
    final doc = await _db.collection("users").doc(doctorId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc.data()!);
  }

  Future<void> updateDoctorProfile(String uid, DoctorProfile profile) async {
    await _db.collection('users').doc(uid).update({
      'doctorProfile': profile.toFirestore(),
    });
  }

  // ---------------- DOCTOR RATING OPERATIONS ----------------
  Future<void> addOrUpdateDoctorRating(DoctorRating rating) async {
    final doctorRef = _db.collection('users').doc(rating.doctorId);
    final ratingsColRef = _db.collection('doctor_ratings');

    await _db.runTransaction((transaction) async {
      final existingRatingQuery = await ratingsColRef
          .where('userId', isEqualTo: rating.userId)
          .where('doctorId', isEqualTo: rating.doctorId)
          .limit(1)
          .get();

      if (existingRatingQuery.docs.isNotEmpty) {
        final existingRatingDoc = existingRatingQuery.docs.first;
        transaction.update(existingRatingDoc.reference, rating.toFirestore());
      } else {
        final newRatingRef = ratingsColRef.doc();
        transaction.set(newRatingRef, rating.toFirestore());
      }

      final allRatingsSnapshot = await ratingsColRef
          .where('doctorId', isEqualTo: rating.doctorId)
          .get();
      
      final allRatings = allRatingsSnapshot.docs
          .map((doc) => DoctorRating.fromFirestore(doc.data(), doc.id))
          .toList();

      allRatings.removeWhere((r) => r.userId == rating.userId);
      allRatings.add(rating);

      final totalRatings = allRatings.length;
      final averageRating = totalRatings == 0
          ? 0.0
          : allRatings.fold<double>(0.0, (sum, item) => sum + item.rating) / totalRatings;

      final doctorDoc = await transaction.get(doctorRef);
      if (doctorDoc.exists) {
        final doctorProfile = DoctorProfile.fromFirestore(doctorDoc.data()?['doctorProfile']);
        final updatedProfile = doctorProfile.copyWith(
          averageRating: averageRating,
          totalReviews: totalRatings,
        );
        transaction.update(doctorRef, {'doctorProfile': updatedProfile.toFirestore()});
      }
    });
  }
  
  Stream<List<DoctorRating>> getDoctorRatings(String doctorId) {
    return _db
        .collection('doctor_ratings')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DoctorRating.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<DoctorRating?> getUserRatingForDoctor(String userId, String doctorId) async {
    final snapshot = await _db
        .collection('doctor_ratings')
        .where('userId', isEqualTo: userId)
        .where('doctorId', isEqualTo: doctorId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    
    final doc = snapshot.docs.first;
    return DoctorRating.fromFirestore(doc.data(), doc.id);
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

  // ---------------- MEDICINE REMINDER OPERATIONS ----------------
  CollectionReference<MedicineModel> _getMedicinesCollection() {
    return _db.collection('medicines').withConverter<MedicineModel>(
          fromFirestore: (snapshot, _) => MedicineModel.fromFirestore(snapshot),
          toFirestore: (medicine, _) => medicine.toFirestore(),
        );
  }

  Future<DocumentReference<MedicineModel>> addMedicine(
      MedicineModel medicine) async {
    return _getMedicinesCollection().add(medicine);
  }

  Stream<List<MedicineModel>> getMedicines(String userId) {
    return _getMedicinesCollection()
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Updates an existing medicine reminder.
  /// The MedicineModel must have a valid ID.
  Future<void> updateMedicine(MedicineModel medicine) async {
    if (medicine.id == null) {
      throw ArgumentError("Medicine ID cannot be null when updating.");
    }
    // vvvvvvvvvv THE FIX IS APPLIED HERE vvvvvvvvvv
    await _getMedicinesCollection()
        .doc(medicine.id!) // Use ! to assert non-null
        .update(medicine.toFirestore());
    // ^^^^^^^^^^ THE FIX IS APPLIED HERE ^^^^^^^^^^
  }

  /// Deletes a medicine reminder from Firestore.
  Future<void> deleteMedicine(String medicineId) async {
    await _getMedicinesCollection().doc(medicineId).delete();
  }

  // ... (all other methods like CHAT and COMMUNITY POST operations remain the same) ...
  // ---------------- CHAT OPERATIONS ----------------
  CollectionReference _getChatCollection(String userId) {
    return _db.collection('users').doc(userId).collection('chatHistory');
  }

  Future<void> addChatMessage(ChatMessageModel message) async {
    try {
      await _getChatCollection(message.userId).add(message.toFirestore());
    } catch (e) {
      print("Error adding chat message to Firestore: $e");
      rethrow;
    }
  }

  Stream<List<ChatMessageModel>> getChatHistory(String userId) {
    return _getChatCollection(userId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList();
    });
  }

  // ---------------- COMMUNITY POST OPERATIONS ----------------
  Future<void> createPost(PostModel post) async {
    await _db.collection('community_posts').add(post.toFirestore());
  }

  Stream<List<PostModel>> getCommunityPosts() {
    return _db
        .collection('community_posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  Future<void> toggleLikePost(
      String postId, String userId, bool isLiked) async {
    final postRef = _db.collection('community_posts').doc(postId);
    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([userId])
      });
    }
  }
    //--------- THIS METHOD TO SAVE THE DIET CHAT ENTRY----------
    
  Future<void> saveDietSuggestion(DietChatEntry suggestion) async {
    try {
      await _db
          .collection('users')
          .doc(suggestion.userId)
          .collection('diet_suggestions')
          .add(suggestion.toFirestore());
    } catch (e) {
      // It's good practice to handle potential errors
      print("❌ Error saving diet suggestion: $e");
      rethrow; // Re-throw the error to be caught by the UI
    }
  }

}