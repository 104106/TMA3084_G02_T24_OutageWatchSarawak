class AppUser {
  final String uid, name, email, phone, role;
  final bool isActive;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        role: m['role'] ?? 'customer',
        isActive: m['isActive'] ?? true,
      );
}