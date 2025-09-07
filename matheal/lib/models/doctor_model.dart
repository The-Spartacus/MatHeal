class Doctor {
  final String id;
  final String name;
  final String hospital;
  final String specialization;
  final String email;

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
      email: data['email'] ?? '',
    );
  }

  // Optional computed getter (useful if you want a default/human-friendly value)
  String get hospitalName => hospital.isNotEmpty ? hospital : 'Unknown Hospital';

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'hospital': hospital,
      'specialization': specialization,
      'email': email,
    };
  }
}
