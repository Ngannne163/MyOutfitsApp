class UserModel {
  final String uid;
  final String username;
  final String? profile;
  final String? email;
  final String? gender;
  final String? nickname;
  final double? height;
  final List<String> styles;
  final List<String> following;
  final List<String> followers;

  UserModel({
    required this.uid,
    required this.username,
    this.profile,
    this.height,
    this.email,
    this.gender,
    this.nickname,
    required this.styles,
    required this.following,
    required this.followers
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      username: data['username'] ?? 'Người dùng ẩn danh',
      profile: data['profile'],
      email: data['email'],
      gender: data['gender'],
      nickname: data['nickname'],
      height: (data['height'] as num?)?.toDouble(),
      styles: List<String>.from(data['styles']?? []),
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'profile': profile,
      'email': email,
      'gender': gender,
      'nickname': nickname,
      'height': height,
      'following': following,
      'followers': followers,
    };
  }
}