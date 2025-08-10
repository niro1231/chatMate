class User {
  int? id;
  String email;
  String name;
  String createdAt;
  String updatedAt;

  User({
    this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    map['email'] = email;
    map['name'] = name;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }
}
