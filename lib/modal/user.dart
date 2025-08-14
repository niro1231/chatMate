class User {
  String uuid;
  String email;
  String name;
  String about;
  String? profileImagePath;
  String createdAt;
  String updatedAt;

  User({
    required this.uuid,
    required this.email,
    required this.name,
    this.about = "Available",
    this.profileImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['uuid'] = uuid;
    map['email'] = email;
    map['name'] = name;
    map['about'] = about;
    map['profileImagePath'] = profileImagePath;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uuid: map['uuid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      about: map['about'] as String? ?? 'Available',
      profileImagePath: map['profileImagePath'] as String?,
      createdAt: map['createdAt'] as String? ?? '',
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }
}
