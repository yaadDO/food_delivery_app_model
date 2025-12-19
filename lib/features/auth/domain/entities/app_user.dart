class AppUser {
  final String uid;
  final String email;
  final String name;
  final bool isAdmin;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.isAdmin = false,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': name,
    'isAdmin': isAdmin,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: json['uid'],
    email: json['email'],
    name: json['name'],
    isAdmin: json['isAdmin'] ?? false,
  );
}