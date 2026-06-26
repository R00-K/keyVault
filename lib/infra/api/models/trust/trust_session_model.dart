import 'trust_method.dart';
import 'trust_state.dart';

class TrustSessionModel {
  final String sessionId;

  final TrustMethod method;

  final TrustState state;

  final String publicKey;

  final String? peerPublicKey;

  const TrustSessionModel({
    required this.sessionId,
    required this.method,
    required this.state,
    required this.publicKey,
    this.peerPublicKey,
  });

  TrustSessionModel copyWith({
    TrustState? state,
    String? peerPublicKey,
    String? publicKey,
  }) {
    return TrustSessionModel(
      sessionId: sessionId,
      method: method,
      state: state ?? this.state,
      publicKey: publicKey ?? this.publicKey,
      peerPublicKey: peerPublicKey ?? this.peerPublicKey,
    );
  }
}
