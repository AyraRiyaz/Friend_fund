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
          json['phone'] ??
          json['mobileNumber'] ??
          json['phoneNumber'] ??
          '', // Support multiple field names, prioritizing 'phone' from API
      email: json['email'] ?? '',
      upiId:
          json['upiId'] ??
          (json['prefs'] != null
              ? json['prefs']['upiId']
              : null), // Check prefs for upiId
      profileImage:
          json['profileImage'] ??
          (json['prefs'] != null
              ? json['prefs']['profileImage']
              : null), // Check prefs for profileImage
      joinedAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['joinedAt'] != null
                ? DateTime.parse(json['joinedAt'])
                : (json['prefs'] != null && json['prefs']['joinedAt'] != null
                      ? DateTime.parse(json['prefs']['joinedAt'])
                      : DateTime.now())), // Check multiple timestamp sources
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
      // Removed timestamp fields since they're not in the database schema
    };
  }
}
