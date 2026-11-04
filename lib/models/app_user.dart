class AppUser {
  final String id;
  final String fullName;
  final String role;
  const AppUser({required this.id, required this.fullName, required this.role});
  bool get isAdmin => role == 'admin' || role == 'super_admin';
  bool get isTeacher => role == 'teacher';
}
