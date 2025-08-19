class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': createdAt,
    };
  }
}

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