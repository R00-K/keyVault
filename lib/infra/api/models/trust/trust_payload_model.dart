class TrustPayloadModel {
  final String sessionId;
  final String keyVaultId;
  final String displayName;
  final String publicKey;
  final int timestamp;

  const TrustPayloadModel({
    required this.sessionId,
    required this.keyVaultId,
    required this.displayName,
    required this.publicKey,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      "sessionId": sessionId,
      "keyVaultId": keyVaultId,
      "displayName": displayName,
      "publicKey": publicKey,
      "timestamp": timestamp,
    };
  }

  factory TrustPayloadModel.fromMap(Map<String, dynamic> map) {
    return TrustPayloadModel(
      sessionId: map["sessionId"],
      keyVaultId: map["keyVaultId"],
      displayName: map["displayName"],
      publicKey: map["publicKey"],
      timestamp: map["timestamp"],
    );
  }
}
