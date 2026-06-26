import 'dart:math';
import '../models/trust/trust_method.dart';
import '../models/trust/trust_state.dart';
import '../models/trust/trust_session_model.dart';
import '../models/trust/trust_payload_model.dart';
import '../models/trust/trusted_contact_model.dart';

class KeyExchangeService {
  KeyExchangeService._();

  // 🔐 PRIVATE KEY STORE (TEMPORARY - replace with SecureStorage later)
  static String? _privateKey;

  /// STEP 1: Start Trust
  static Future<TrustSessionModel> startTrustEstablishment({
    required TrustMethod method,
  }) async {
    final sessionId = _generateId();

    final publicKey = _generateFakeKey();

    _privateKey = _generateFakeKey(); // ONLY HERE

    return TrustSessionModel(
      sessionId: sessionId,
      method: method,
      state: TrustState.keyGenerated,
      publicKey: publicKey,
    );
  }

  /// STEP 2: Build QR Payload
  static TrustPayloadModel buildQrPayload({
    required TrustSessionModel session,
    required String keyVaultId,
    required String displayName,
  }) {
    return TrustPayloadModel(
      sessionId: session.sessionId,
      keyVaultId: keyVaultId,
      displayName: displayName,
      publicKey: session.publicKey,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isResponse: false,
    );
  }

  /// STEP 3: Receive Payload
  static Future<TrustSessionModel> receiveTrustRequest({
    required TrustPayloadModel payload,
  }) async {
    final publicKey = _generateFakeKey();

    _privateKey = _generateFakeKey(); // receiver private key (temporary)

    return TrustSessionModel(
      sessionId: payload.sessionId,

      // ✅ FIX: do NOT hardcode qr
      method: TrustMethod.qr, // ONLY if you're strictly QR-only for now

      state: TrustState.received,

      publicKey: publicKey,

      peerPublicKey: payload.publicKey,
    );
  }

  static TrustPayloadModel generateResponsePayload({
    required TrustSessionModel session,
    required String keyVaultId,
    required String displayName,
  }) {
    return TrustPayloadModel(
      sessionId: session.sessionId,
      keyVaultId: keyVaultId,
      displayName: displayName,
      publicKey: session.publicKey,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isResponse: false,
    );
  }

  /// STEP 4: Verify Trust
  static Future<bool> verifyTrust({required TrustSessionModel session}) async {
    return true; // later fingerprint comparison
  }

  /// STEP 5: Create Trusted Contact
  static Future<TrustedContactModel> establishTrustedContact({
    required TrustSessionModel session,
    required String keyVaultId,
    required String displayName,
  }) async {
    return TrustedContactModel(
      contactId: session.sessionId,
      keyVaultId: keyVaultId,
      displayName: displayName,
      publicKey: session.peerPublicKey ?? '',
      createdAt: DateTime.now(),
    );
  }

  // -----------------------
  // INTERNAL HELPERS
  // -----------------------

  static String _generateFakeKey() {
    return List.generate(32, (_) => Random().nextInt(255)).join();
  }

  static String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
