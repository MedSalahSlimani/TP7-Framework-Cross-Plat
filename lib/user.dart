class User {
  int id;
  String username;
  List<String> roles;

  User(this.id, this.username, this.roles);

  factory User.fromMap(Map<String, dynamic> map) => User(
    map["id"],
    map["username"],
    List<String>.from(map["roles"] ?? []),
  );
}
