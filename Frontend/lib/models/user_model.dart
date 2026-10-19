class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String? phone;
  final Set<String> roles;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.phone,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['userId'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
    );
  }

  bool get isAdmin => roles.contains('ROLE_ADMIN');
}
