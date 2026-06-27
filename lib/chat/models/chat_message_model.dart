import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String from;
  final String to;
  final String sessionId;
  final String cipherText;
  final String nonce;
  final String mac;
  final Timestamp timestamp;

  const ChatMessageModel({
    required this.from,
    required this.to,
    required this.sessionId,
    required this.cipherText,
    required this.nonce,
    required this.mac,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'sessionId': sessionId,
      'cipherText': cipherText,
      'nonce': nonce,
      'mac': mac,
      'timestamp': timestamp,
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      from: map['from'] as String,
      to: map['to'] as String,
      sessionId: map['sessionId'] as String,
      cipherText: map['cipherText'] as String,
      nonce: map['nonce'] as String,
      mac: map['mac'] as String,
      timestamp: map['timestamp'] as Timestamp,
    );
  }
}
