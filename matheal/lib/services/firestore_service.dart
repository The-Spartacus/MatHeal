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

    // Use the specific user's rating document reference for writes
    final userRatingQuery = ratingsColRef
        .where('userId', isEqualTo: rating.userId)
        .where('doctorId', isEqualTo: rating.doctorId)
        .limit(1);

    await _db.runTransaction((transaction) async {
      // --- 1. READ ALL NECESSARY DOCUMENTS FIRST ---

      // Read the doctor's main document
      final doctorDoc = await transaction.get(doctorRef);

      // Read all ratings for this doctor
      final allRatingsSnapshot = await ratingsColRef
          .where('doctorId', isEqualTo: rating.doctorId)
          .get();
      
      // Read the current user's existing rating document (if it exists)
      final existingRatingSnapshot = await userRatingQuery.get();

      // --- 2. PERFORM LOGIC WITH THE READ DATA ---

      if (!doctorDoc.exists) {
        throw Exception("Doctor does not exist!");
      }

      // Convert all ratings to a mutable list
      final allRatings = allRatingsSnapshot.docs
          .map((doc) => DoctorRating.fromFirestore(doc.data(), doc.id))
          .toList();

      // Remove the user's old rating from the list if it exists, to avoid double-counting
      allRatings.removeWhere((r) => r.userId == rating.userId);
      // Add the new rating to the list
      allRatings.add(rating);

      // Recalculate the average and total
      final totalRatings = allRatings.length;
      final averageRating = totalRatings == 0
          ? 0.0
          : allRatings.fold<double>(0.0, (sum, item) => sum + item.rating) / totalRatings;
      
      final doctorProfile = DoctorProfile.fromFirestore(doctorDoc.data()?['doctorProfile']);
      final updatedProfile = doctorProfile.copyWith(
        averageRating: averageRating,
        totalReviews: totalRatings,
      );

      // --- 3. PERFORM ALL WRITE OPERATIONS LAST ---
      
      // Update or create the user's specific rating document
      if (existingRatingSnapshot.docs.isNotEmpty) {
        // If the user has an existing rating, update it
        final existingRatingRef = existingRatingSnapshot.docs.first.reference;
        transaction.update(existingRatingRef, rating.toFirestore());
      } else {
        // If it's a new rating, create a new document
        final newRatingRef = ratingsColRef.doc();
        transaction.set(newRatingRef, rating.toFirestore());
      }

      // Update the doctor's aggregated profile data
      transaction.update(doctorRef, {'doctorProfile': updatedProfile.toFirestore()});
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

  Future<void> updateMedicine(MedicineModel medicine) async {
    if (medicine.id == null) {
      throw ArgumentError("Medicine ID cannot be null when updating.");
    }
    await _getMedicinesCollection()
        .doc(medicine.id!)
        .update(medicine.toFirestore());
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _getMedicinesCollection().doc(medicineId).delete();
  }

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
  
  // ---------------- DIET SUGGESTION OPERATIONS ----------------
    
  Future<void> saveDietSuggestion(DietChatEntry suggestion) async {
    try {
      await _db
          .collection('users')
          .doc(suggestion.userId)
          .collection('diet_suggestions')
          .add(suggestion.toFirestore());
    } catch (e) {
      print("❌ Error saving diet suggestion: $e");
      rethrow;
    }
  }

  // ✅ ADDED THIS METHOD TO GET THE LATEST DIET SUGGESTION
  Future<DietChatEntry?> getLatestDietSuggestion(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('diet_suggestions')
          .orderBy('timestamp', descending: true) // Get the newest first
          .limit(1) // We only need the most recent one
          .get();

      if (snapshot.docs.isEmpty) {
        return null; // No suggestions found
      }
      // Convert the first document to a DietChatEntry object and return it
      return DietChatEntry.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print("❌ Error fetching latest diet suggestion: $e");
      return null;
    }
  }


  }