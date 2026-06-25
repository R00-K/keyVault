import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String keyVaultId;
  final String username;
  final String displayName;
  final String email;
  final String phoneNumber;
  final String? photoUrl;
  final Timestamp dateOfBirth;
  final Timestamp createdAt;
  final Timestamp? lastSeen;
  final bool isOnline;

  const UserModel({
    required this.uid,
    required this.keyVaultId,
    required this.username,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    this.photoUrl,
    required this.dateOfBirth,
    required this.createdAt,
    this.lastSeen,
    required this.isOnline,
  });

  factory UserModel.create({
    required String uid,
    required String keyVaultId,
    required String displayName,
    required String email,
    required String phoneNumber,
    required Timestamp dateOfBirth,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid,
      keyVaultId: keyVaultId,
      username: '',
      displayName: displayName,
      email: email,
      phoneNumber: phoneNumber,
      photoUrl: photoUrl,
      dateOfBirth: dateOfBirth,
      createdAt: Timestamp.now(),
      isOnline: true,
    );
  }

  UserModel copyWith({
    String? uid,
    String? keyVaultId,
    String? username,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    Timestamp? dateOfBirth,
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
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
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
      phoneNumber: map['phoneNumber'] ?? '',
      photoUrl: map['photoUrl'],
      dateOfBirth: map['dateOfBirth'] ?? Timestamp.now(),
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
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'dateOfBirth': dateOfBirth,
      'createdAt': createdAt,
      'lastSeen': lastSeen,
      'isOnline': isOnline,
    };
  }
}
