import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String keyVaultId;
  final String username;
  final String displayName;
  final String email;
  final String? photoUrl;
  final Timestamp createdAt;
  final Timestamp? lastSeen;
  final bool isOnline;

  const UserModel({
    required this.uid,
    required this.keyVaultId,
    required this.username,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.lastSeen,
    required this.isOnline,
  });

  UserModel copyWith({
    String? uid,
    String? keyVaultId,
    String? username,
    String? displayName,
    String? email,
    String? photoUrl,
    Timestamp? createdAt,
    Timestamp? lastSeen,
    bool? isOnline,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      keyVaultId: keyVaultId ?? this.keyVaultId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      keyVaultId: map['keyVaultId'] ?? '',
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      lastSeen: map['lastSeen'],
      isOnline: map['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'keyVaultId': keyVaultId,
      'username': username,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'lastSeen': lastSeen,
      'isOnline': isOnline,
    };
  }
}
