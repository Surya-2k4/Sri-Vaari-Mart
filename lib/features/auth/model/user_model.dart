class AppUser {
  final String id;
  final String email;

  AppUser({required this.id, required this.email});

  factory AppUser.fromSupabase(Map<String, dynamic> data) {
    return AppUser(id: data['id'], email: data['email']);
  }
}
