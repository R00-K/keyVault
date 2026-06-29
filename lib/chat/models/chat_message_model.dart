class ChatMessageModel {
  final String messageId;
  final String from;
  final String to;
  final String sessionId;
  final String cipherText;
  final String nonce;
  final String mac;
  final String? plainText;
  final int timestamp;
  final String status;

  const ChatMessageModel({
    required this.messageId,
    required this.from,
    required this.to,
    required this.sessionId,
    required this.cipherText,
    required this.nonce,
    required this.mac,
    this.plainText,
    required this.timestamp,
    this.status = 'sent',
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'from': from,
      'to': to,
      'sessionId': sessionId,
      'cipherText': cipherText,
      'nonce': nonce,
      'mac': mac,
      'timestamp': timestamp,
      'status': status,
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      messageId: map['messageId'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      sessionId: map['sessionId'] ?? '',
      cipherText: map['cipherText'] ?? '',
      nonce: map['nonce'] ?? '',
      mac: map['mac'] ?? '',
      timestamp: map['timestamp'] ?? 0,
      status: map['status'] ?? 'sent',
    );
  }

  ChatMessageModel copyWith({
    String? messageId,
    String? from,
    String? to,
    String? sessionId,
    String? cipherText,
    String? nonce,
    String? mac,
    String? plainText,
    int? timestamp,
    String? status,
  }) {
    return ChatMessageModel(
      messageId: messageId ?? this.messageId,
      from: from ?? this.from,
      to: to ?? this.to,
      sessionId: sessionId ?? this.sessionId,
      cipherText: cipherText ?? this.cipherText,
      nonce: nonce ?? this.nonce,
      mac: mac ?? this.mac,
      plainText: plainText ?? this.plainText,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
