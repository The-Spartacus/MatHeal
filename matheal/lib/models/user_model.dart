// ---------------- USER MODEL ----------------
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final String role; // "user" or "doctor"
  final DoctorProfile? doctorProfile;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.role = "user",
    this.doctorProfile,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      role: data['role'] ?? 'user',
      doctorProfile: data['doctorProfile'] != null
          ? DoctorProfile.fromFirestore(data['doctorProfile'])
          : null,
    );
  }

  String? get specialization => doctorProfile?.specialization;
  String? get hospitalName => doctorProfile?.hospitalName;
  String? get avatarUrl => doctorProfile?.avatarUrl;
  double get averageRating => doctorProfile?.averageRating ?? 0.0;
  int get totalReviews => doctorProfile?.totalReviews ?? 0;

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': createdAt,
      'role': role,
      if (doctorProfile != null) 'doctorProfile': doctorProfile!.toFirestore(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    DateTime? createdAt,
    String? role,
    DoctorProfile? doctorProfile,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      doctorProfile: doctorProfile ?? this.doctorProfile,
    );
  }
}

// ---------------- DOCTOR PROFILE (ENHANCED) ----------------
class DoctorProfile {
  final String specialization;
  final String hospitalName;
  final String? avatarUrl;
  final String? bio;
  final int? yearsOfExperience;
  final String? qualifications;
  final Map<String, bool> availableTimings;
  final double averageRating;
  final int totalReviews;

  DoctorProfile({
    required this.specialization,
    required this.hospitalName,
    this.avatarUrl,
    this.bio,
    this.yearsOfExperience,
    this.qualifications,
    this.availableTimings = const {'morning': false, 'afternoon': false, 'evening': false},
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  factory DoctorProfile.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return DoctorProfile(specialization: "", hospitalName: "");
    return DoctorProfile(
      specialization: data['specialization'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      avatarUrl: data['avatarUrl'],
      bio: data['bio'],
      yearsOfExperience: data['yearsOfExperience'],
      qualifications: data['qualifications'],
      availableTimings: Map<String, bool>.from(data['availableTimings'] ?? {}),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'specialization': specialization,
      'hospitalName': hospitalName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'yearsOfExperience': yearsOfExperience,
      'qualifications': qualifications,
      'availableTimings': availableTimings,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }

  DoctorProfile copyWith({
    String? specialization,
    String? hospitalName,
    String? avatarUrl,
    String? bio,
    int? yearsOfExperience,
    String? qualifications,
    Map<String, bool>? availableTimings,
    double? averageRating,
    int? totalReviews,
  }) {
    return DoctorProfile(
      specialization: specialization ?? this.specialization,
      hospitalName: hospitalName ?? this.hospitalName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      qualifications: qualifications ?? this.qualifications,
      availableTimings: availableTimings ?? this.availableTimings,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}

// ---------------- DOCTOR RATING MODEL ----------------
class DoctorRating {
  final String? id;
  final String doctorId;
  final String userId;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final String patientName;

  DoctorRating({
    this.id,
    required this.doctorId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.patientName,
  });

  factory DoctorRating.fromFirestore(Map<String, dynamic> data, String id) {
    return DoctorRating(
      id: id,
      doctorId: data['doctorId'] ?? '',
      userId: data['userId'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      patientName: data['patientName'] ?? 'Anonymous',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'doctorId': doctorId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'patientName': patientName,
    };
  }
}



/// ---------------- USER PROFILE ----------------
class UserProfile {
  final String uid;
  final int? age;
  final int? weeksPregnant;
  final List<String> conditions;
  final String? avatarUrl;

  UserProfile({
    required this.uid,
    this.age,
    this.weeksPregnant,
    this.conditions = const [],
    this.avatarUrl,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] ?? '',
      age: data['age'],
      weeksPregnant: data['weeksPregnant'],
      conditions: List<String>.from(data['conditions'] ?? []),
      avatarUrl: data['avatarUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'age': age,
      'weeksPregnant': weeksPregnant,
      'conditions': conditions,
      'avatarUrl': avatarUrl,
    };
  }

  UserProfile copyWith({
    String? uid,
    int? age,
    int? weeksPregnant,
    List<String>? conditions,
    String? avatarUrl,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      age: age ?? this.age,
      weeksPregnant: weeksPregnant ?? this.weeksPregnant,
      conditions: conditions ?? this.conditions,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}