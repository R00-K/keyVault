import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:keyvault/infra/api/models/key_request_model.dart';
import 'package:keyvault/infra/api/services/firestore_service.dart';

class KeyService {
  KeyService._();

  static const String _collection = 'key_requests';

  static Future<KeyRequestModel> sendKeyRequest({
    required String senderId,
    required String receiverId,
  }) async {
    if (senderId == receiverId) {
      throw ArgumentError('You cannot send a key request to yourself.');
    }

    final existingRequest = await _getPendingRequestBetween(
      senderId,
      receiverId,
    );

    if (existingRequest != null) {
      throw StateError('A pending key request already exists.');
    }

    final document = FirestoreService.collection(_collection).doc();
    final request = KeyRequestModel.create(
      id: document.id,
      senderId: senderId,
      receiverId: receiverId,
    );

    await document.set(request.toMap());
    return request;
  }

  static Future<List<KeyRequestModel>> getIncomingKeyRequests({
    required String userId,
  }) async {
    final snapshot = await FirestoreService.collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: KeyRequestStatus.pending.name)
        .get();

    return _requestsFromSnapshot(snapshot);
  }

  static Future<List<KeyRequestModel>> getOutgoingKeyRequests({
    required String userId,
  }) async {
    final snapshot = await FirestoreService.collection(_collection)
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: KeyRequestStatus.pending.name)
        .get();

    return _requestsFromSnapshot(snapshot);
  }

  static Future<void> acceptKeyRequest(String requestId) async {
    await _updateRequestStatus(requestId, KeyRequestStatus.accepted);
  }

  static Future<void> rejectKeyRequest(String requestId) async {
    await _updateRequestStatus(requestId, KeyRequestStatus.rejected);
  }

  static Future<void> cancelKeyRequest(String requestId) async {
    await FirestoreService.collection(_collection).doc(requestId).delete();
  }

  static Future<void> _updateRequestStatus(
    String requestId,
    KeyRequestStatus status,
  ) async {
    await FirestoreService.collection(
      _collection,
    ).doc(requestId).update({'status': status.name});
  }

  static Future<KeyRequestModel?> _getPendingRequestBetween(
    String firstUserId,
    String secondUserId,
  ) async {
    final sentRequest = await _getPendingRequest(
      senderId: firstUserId,
      receiverId: secondUserId,
    );
    if (sentRequest != null) return sentRequest;

    return _getPendingRequest(senderId: secondUserId, receiverId: firstUserId);
  }

  static Future<KeyRequestModel?> _getPendingRequest({
    required String senderId,
    required String receiverId,
  }) async {
    final snapshot = await FirestoreService.collection(_collection)
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: KeyRequestStatus.pending.name)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return KeyRequestModel.fromMap(snapshot.docs.first.data());
  }

  static List<KeyRequestModel> _requestsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final requests = snapshot.docs
        .map((document) => KeyRequestModel.fromMap(document.data()))
        .toList();

    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }
}
