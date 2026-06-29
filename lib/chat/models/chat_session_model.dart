class ChatSessionModel {
  final String sessionId;
  final String contactId;
  final String keyVaultId;
  final String displayName;
  final String peerPublicKey;
  final bool isTrusted;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  const ChatSessionModel({
    required this.sessionId,
    required this.contactId,
    required this.keyVaultId,
    required this.displayName,
    required this.peerPublicKey,
    required this.isTrusted,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'contactId': contactId,
      'keyVaultId': keyVaultId,
      'displayName': displayName,
      'peerPublicKey': peerPublicKey,
      'isTrusted': isTrusted,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
    };
  }

  factory ChatSessionModel.fromMap(Map<String, dynamic> map) {
    return ChatSessionModel(
      sessionId: map['sessionId'] ?? '',
      contactId: map['contactId'] ?? '',
      keyVaultId: map['keyVaultId'] ?? '',
      displayName: map['displayName'] ?? '',
      peerPublicKey: map['peerPublicKey'] ?? '',
      isTrusted: map['isTrusted'] ?? false,
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime'])
          : null,
      unreadCount: map['unreadCount'] ?? 0,
    );
  }

  ChatSessionModel copyWith({
    String? sessionId,
    String? contactId,
    String? keyVaultId,
    String? displayName,
    String? peerPublicKey,
    bool? isTrusted,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatSessionModel(
      sessionId: sessionId ?? this.sessionId,
      contactId: contactId ?? this.contactId,
      keyVaultId: keyVaultId ?? this.keyVaultId,
      displayName: displayName ?? this.displayName,
      peerPublicKey: peerPublicKey ?? this.peerPublicKey,
      isTrusted: isTrusted ?? this.isTrusted,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
