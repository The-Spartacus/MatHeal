// lib/models/doctor_model.dart
class Doctor {
  final String id;
  final String name;
  final String hospital;
  final String specialization;
  final String email; // ✅ New field

  Doctor({
    required this.id,
    required this.name,
    required this.hospital,
    required this.specialization,
    required this.email,
  });

  factory Doctor.fromFirestore(Map<String, dynamic> data, String id) {
    return Doctor(
      id: id,
      name: data['name'] ?? '',
      hospital: data['hospital'] ?? '',
      specialization: data['specialization'] ?? '',
      email: data['email'] ?? '', // ✅ Handle null safely
    );
  }

  get hospitalName => null;

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'hospital': hospital,
      'specialization': specialization,
      'email': email, // ✅ Save email
    };
  }
}
