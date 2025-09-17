import 'package:flutter/foundation.dart';

/// ---------------- USER MODEL ----------------
class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final String role; // "user" or "doctor"
  final DoctorProfile? doctorProfile;
// 👈 present only if doctor

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
  // Getter for doctor's avatar
  String? get avatarUrl => doctorProfile?.avatarUrl;

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

/// ---------------- DOCTOR PROFILE (UPDATED) ----------------
class DoctorProfile {
  final String specialization;
  final String hospitalName;
  final String? avatarUrl; // ✅ ADDED

  DoctorProfile({
    required this.specialization,
    required this.hospitalName,
    this.avatarUrl, // ✅ ADDED
  });

  factory DoctorProfile.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return DoctorProfile(specialization: "", hospitalName: "");
    }
    return DoctorProfile(
      specialization: data['specialization'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      avatarUrl: data['avatarUrl'], // ✅ ADDED
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'specialization': specialization,
      'hospitalName': hospitalName,
      'avatarUrl': avatarUrl, // ✅ ADDED
    };
  }

  DoctorProfile copyWith({ // ✅ ADDED copyWith for easier updates
    String? specialization,
    String? hospitalName,
    String? avatarUrl,
  }) {
    return DoctorProfile(
      specialization: specialization ?? this.specialization,
      hospitalName: hospitalName ?? this.hospitalName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
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

/// ---------------- REMINDER MODEL ----------------
class ReminderModel {
  final String? id;
  final String uid;
  final String type;
  final String title;
  final String notes;
  final DateTime time;
  final String repeatInterval;
  final Map<String, dynamic> meta;

  ReminderModel({
    this.id,
    required this.uid,
    required this.type,
    required this.title,
    required this.notes,
    required this.time,
    required this.repeatInterval,
    this.meta = const {},
  });

  factory ReminderModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReminderModel(
      id: id,
      uid: data['uid'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      notes: data['notes'] ?? '',
      time: (data['time'] as dynamic)?.toDate() ?? DateTime.now(),
      repeatInterval: data['repeatInterval'] ?? 'none',
      meta: Map<String, dynamic>.from(data['meta'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'type': type,
      'title': title,
      'notes': notes,
      'time': time,
      'repeatInterval': repeatInterval,
      'meta': meta,
    };
  }
}

/// ---------------- CONSUMED MEDICINE ----------------
class ConsumedMedicine {
  final String? id;
  final String uid;
  final String reminderId;
  final String name;
  final DateTime consumedAt;

  ConsumedMedicine({
    this.id,
    required this.uid,
    required this.reminderId,
    required this.name,
    required this.consumedAt,
  });

  factory ConsumedMedicine.fromFirestore(Map<String, dynamic> data, String id) {
    return ConsumedMedicine(
      id: id,
      uid: data['uid'] ?? '',
      reminderId: data['reminderId'] ?? '',
      name: data['name'] ?? '',
      consumedAt: (data['consumedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'reminderId': reminderId,
      'name': name,
      'consumedAt': consumedAt,
    };
  }
}

