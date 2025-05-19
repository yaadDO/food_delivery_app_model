//The AppUser class represents a user in the Flutter app, providing a structured way to handle user data such as uid, email, and name

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

  // Update toJson
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': name,
    'isAdmin': isAdmin,
  };

  // Update fromJson
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: json['uid'],
    email: json['email'],
    name: json['name'],
    isAdmin: json['isAdmin'] ?? false,
  );
}