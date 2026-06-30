import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:keyvault/watch/models/local_video_model.dart';
import 'package:keyvault/watch/models/watch_session_model.dart';
import 'package:keyvault/watch/repository/watch_repository.dart';

class WatchService {
  WatchService._();

  /// Pick a video from device storage.
  static Future<LocalVideoModel?> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;

    if (file.path == null) {
      return null;
    }

    final watchSessionId = _generateWatchSessionId();

    return LocalVideoModel(
      watchSessionId: watchSessionId,
      videoPath: file.path!,
      videoName: file.name,
      mimeType: file.extension ?? 'video/mp4',
      videoSize: file.size,
      videoDurationMs: 0, // TODO: Read actual duration later.
      thumbnailPath: null, // TODO: Generate thumbnail later.
    );
  }

  /// Host starts a Watch Together session.
  static Future<WatchSessionModel> startWatchSession({
    required String chatSessionId,
    required String viewerUid,
    required LocalVideoModel localVideo,
  }) async {
    final hostUid = FirebaseAuth.instance.currentUser!.uid;

    final session = WatchSessionModel(
      watchSessionId: localVideo.watchSessionId,
      chatSessionId: chatSessionId,
      hostUid: hostUid,
      viewerUid: viewerUid,
      videoName: localVideo.videoName,
      mimeType: localVideo.mimeType,
      videoSize: localVideo.videoSize,
      videoDurationMs: localVideo.videoDurationMs,
      thumbnailPath: localVideo.thumbnailPath,
      createdAt: DateTime.now(),
      watchState: WatchState.waiting,
    );

    await WatchRepository.createWatchSession(session);

    return session;
  }

  /// Viewer accepts the invitation.
  static Future<void> acceptWatchSession(
    String watchSessionId,
  ) async {
    await WatchRepository.updateWatchState(
      watchSessionId: watchSessionId,
      state: WatchState.accepted,
    );
  }

  /// Viewer declines the invitation.
  static Future<void> rejectWatchSession(
    String watchSessionId,
  ) async {
    await WatchRepository.updateWatchState(
      watchSessionId: watchSessionId,
      state: WatchState.cancelled,
    );
  }

  /// Host ends the session.
  static Future<void> endWatchSession(
    String watchSessionId,
  ) async {
    await WatchRepository.endWatchSession(
      watchSessionId,
    );
  }

  /// Listen for incoming watch requests.
  static Stream<List<WatchSessionModel>> listenIncomingSessions(
    String viewerUid,
  ) {
    return WatchRepository.listenIncomingSessions(
      viewerUid,
    );
  }

  /// Listen to a specific watch session.
  static Stream<WatchSessionModel?> listenWatchSession(
    String watchSessionId,
  ) {
    return WatchRepository.listenWatchSession(
      watchSessionId,
    );
  }

  /// Generate a unique watch session ID.
  static String _generateWatchSessionId() {
    final random = Random().nextInt(999999);

    return 'watch_${DateTime.now().millisecondsSinceEpoch}_$random';
  }
}