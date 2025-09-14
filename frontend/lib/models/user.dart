class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String? upiId;
  final String? profileImage;
  final DateTime joinedAt;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.upiId,
    this.profileImage,
    required this.joinedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['\$id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber:
          json['mobileNumber'] ??
          json['phoneNumber'] ??
          '', // Support both field names
      email: json['email'] ?? '',
      upiId: json['upiId'],
      profileImage: json['profileImage'],
      joinedAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['joinedAt'] != null
                ? DateTime.parse(json['joinedAt'])
                : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobileNumber': phoneNumber, // Use mobileNumber to match database schema
      'email': email,
      'upiId': upiId,
      'profileImage': profileImage,
      'createdAt': joinedAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}
