import 'package:cloud_firestore/cloud_firestore.dart';

enum KeyRequestStatus {
  pending,
  accepted,
  rejected;

  static KeyRequestStatus fromValue(String? value) {
    return KeyRequestStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => KeyRequestStatus.pending,
    );
  }
}

class KeyRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final KeyRequestStatus status;
  final Timestamp createdAt;

  const KeyRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  factory KeyRequestModel.create({
    required String id,
    required String senderId,
    required String receiverId,
  }) {
    return KeyRequestModel(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      status: KeyRequestStatus.pending,
      createdAt: Timestamp.now(),
    );
  }

  KeyRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    KeyRequestStatus? status,
    Timestamp? createdAt,
  }) {
    return KeyRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory KeyRequestModel.fromMap(Map<String, dynamic> map) {
    return KeyRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: KeyRequestStatus.fromValue(map['status']),
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.name,
      'createdAt': createdAt,
    };
  }
}
