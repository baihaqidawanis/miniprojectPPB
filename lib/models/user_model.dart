class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String role;
  // ATURAN ARSITEKTUR #1: Embed data mapping directly inside document
  final Map<String, dynamic> userSettings;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = 'user',
    this.userSettings = const {},
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'user',
      userSettings: data['userSettings'] != null ? Map<String, dynamic>.from(data['userSettings']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'userSettings': userSettings,
    };
  }
}
