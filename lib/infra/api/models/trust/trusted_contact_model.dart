class TrustedContactModel {
  final String contactId;

  final String keyVaultId;

  final String displayName;

  final String publicKey;

  final DateTime createdAt;

  const TrustedContactModel({
    required this.contactId,
    required this.keyVaultId,
    required this.displayName,
    required this.publicKey,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "contactId": contactId,
      "keyVaultId": keyVaultId,
      "displayName": displayName,
      "publicKey": publicKey,
      "createdAt": createdAt.toIso8601String(),
    };
  }

  factory TrustedContactModel.fromMap(Map<String, dynamic> map) {
    return TrustedContactModel(
      contactId: map["contactId"],
      keyVaultId: map["keyVaultId"],
      displayName: map["displayName"],
      publicKey: map["publicKey"],
      createdAt: DateTime.parse(map["createdAt"]),
    );
  }
}
