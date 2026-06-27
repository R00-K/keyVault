class KeyPairModel {
  final String publicKey;

  const KeyPairModel({required this.publicKey});

  Map<String, dynamic> toMap() {
    return {'publicKey': publicKey};
  }

  factory KeyPairModel.fromMap(Map<String, dynamic> map) {
    return KeyPairModel(publicKey: map['publicKey'] as String);
  }

  KeyPairModel copyWith({String? publicKey}) {
    return KeyPairModel(publicKey: publicKey ?? this.publicKey);
  }
}
