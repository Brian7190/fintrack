class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final int loginCount;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    required this.loginCount,
  });

  bool get isAdmin => role == 'admin';
}
