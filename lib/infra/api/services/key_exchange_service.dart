import '../models/trust/trust_method.dart';
import '../models/trust/trust_state.dart';
import '../models/trust/trust_session_model.dart';
import '../models/trust/trust_payload_model.dart';
import '../models/trust/trusted_contact_model.dart';
import '../../../crypto/crypto_service.dart';

class KeyExchangeService {
  KeyExchangeService._();

  /// STEP 1: Start Trust
  static Future<TrustSessionModel> startTrustEstablishment({
    required TrustMethod method,
  }) async {
    final sessionId = _generateId();

    final keyPair = await CryptoService.generateKeyPair(
      sessionId: sessionId,
    );

    return TrustSessionModel(
      sessionId: sessionId,
      method: method,
      state: TrustState.keyGenerated,
      publicKey: keyPair.publicKey,
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
    final keyPair = await CryptoService.generateKeyPair(
      sessionId: payload.sessionId,
    );

    return TrustSessionModel(
      sessionId: payload.sessionId,
      method: TrustMethod.qr,
      state: TrustState.received,
      publicKey: keyPair.publicKey,
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
      isResponse:true,
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

  /// STEP 6: Complete trust by scanning the response QR
  static Future<TrustedContactModel> completeTrustWithResponse({
    required TrustSessionModel session,
    required TrustPayloadModel responsePayload,
  }) async {
    final updatedSession = session.copyWith(
      peerPublicKey: responsePayload.publicKey,
      state: TrustState.verified,
    );

    return establishTrustedContact(
      session: updatedSession,
      keyVaultId: responsePayload.keyVaultId,
      displayName: responsePayload.displayName,
    );
  }

  // -----------------------
  // INTERNAL HELPERS
  // -----------------------

  static String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
