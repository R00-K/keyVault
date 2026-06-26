import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class TrustEventService {
  TrustEventService._();

  static const String _collection = 'trust_events';

  static Future<void> notifyQrScanned({
    required String sessionId,
    required String receiverKeyVaultId,
  }) async {
    await FirestoreService.document('$_collection/$sessionId').set({
      'type': 'trust_qr_scanned',
      'sessionId': sessionId,
      'receiverKeyVaultId': receiverKeyVaultId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> notifyTrustEstablished({
    required String sessionId,
    required String receiverKeyVaultId,
  }) async {
    await FirestoreService.document('$_collection/$sessionId').set({
      'type': 'trust_established',
      'sessionId': sessionId,
      'receiverKeyVaultId': receiverKeyVaultId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> eventStream({
    required String sessionId,
  }) {
    return FirestoreService.document('$_collection/$sessionId').snapshots();
  }
}
