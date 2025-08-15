class User {
  String uuid;
  String email;
  String name;
  String createdAt;
  String updatedAt;
  String? lastMessage; // Add this line
  DateTime? timestamp;

  User({
    required this.uuid,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage, // Add this line
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['uuid'] = uuid;
    map['email'] = email;
    map['name'] = name;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uuid: map['uuid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      createdAt: map['createdAt'] as String? ?? '',
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }
}
