import 'package:keyvault/infra/api/services/firestore_service.dart';
import 'package:keyvault/watch/models/watch_session_model.dart';

class WatchRepository {
  WatchRepository._();

  static const String _collection = 'watchSessions';

  /// Create a new watch session.
  static Future<void> createWatchSession(
    WatchSessionModel session,
  ) async {
    await FirestoreService.collection(_collection)
        .doc(session.watchSessionId)
        .set(session.toMap());
  }

  /// Get a watch session once.
  static Future<WatchSessionModel?> getWatchSession(
    String watchSessionId,
  ) async {
    final snapshot = await FirestoreService.collection(_collection)
        .doc(watchSessionId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return WatchSessionModel.fromMap(snapshot.data()!);
  }

  /// Listen to a specific watch session.
  static Stream<WatchSessionModel?> listenWatchSession(
    String watchSessionId,
  ) {
    return FirestoreService.collection(_collection)
        .doc(watchSessionId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return WatchSessionModel.fromMap(snapshot.data()!);
    });
  }

  /// Listen for incoming watch requests.
  static Stream<List<WatchSessionModel>> listenIncomingSessions(
    String viewerUid,
  ) {
    return FirestoreService.collection(_collection)
        .where('viewerUid', isEqualTo: viewerUid)
        .where(
          'watchState',
          isEqualTo: WatchState.waiting.name,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => WatchSessionModel.fromMap(doc.data()),
              )
              .toList(),
        );
  }

  /// Update only the session state.
  static Future<void> updateWatchState({
    required String watchSessionId,
    required WatchState state,
  }) async {
    await FirestoreService.collection(_collection)
        .doc(watchSessionId)
        .update({
      'watchState': state.name,
    });
  }

  /// Mark the session as ended.
  static Future<void> endWatchSession(
    String watchSessionId,
  ) async {
    await FirestoreService.collection(_collection)
        .doc(watchSessionId)
        .update({
      'watchState': WatchState.ended.name,
      'endedAt': DateTime.now().toIso8601String(),
    });
  }
}