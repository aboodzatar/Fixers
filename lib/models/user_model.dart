class UserModel {
  final String uid;
  final String email;
  final String role; // 'user' or 'fixer'
  final String? location;
  final String? serviceType; // e.g., 'Home Visits', 'Workshop Only'

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.location,
    this.serviceType,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'location': location,
      'serviceType': serviceType,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      location: map['location'],
      serviceType: map['serviceType'],
    );
  }
}
