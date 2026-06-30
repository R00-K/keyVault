enum WatchState {
  waiting,
  accepted,
  connecting,
  streaming,
  paused,
  ended,
  cancelled,
  failed,
}

class WatchSessionModel {
  /// Unique Watch Together session ID.
  final String watchSessionId;

  /// Chat this session belongs to.
  final String chatSessionId;

  /// User streaming the video.
  final String hostUid;

  /// User watching the stream.
  final String viewerUid;

  /// Video metadata.
  final String videoName;
  final String mimeType;
  final int videoSize;
  final int videoDurationMs;

  /// Optional thumbnail (generated locally by host).
  final String? thumbnailPath;

  /// Current state of the watch session.
  final WatchState watchState;

  /// Session timestamps.
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const WatchSessionModel({
    required this.watchSessionId,
    required this.chatSessionId,
    required this.hostUid,
    required this.viewerUid,
    required this.videoName,
    required this.mimeType,
    required this.videoSize,
    required this.videoDurationMs,
    this.thumbnailPath,
    this.watchState = WatchState.waiting,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'watchSessionId': watchSessionId,
      'chatSessionId': chatSessionId,
      'hostUid': hostUid,
      'viewerUid': viewerUid,
      'videoName': videoName,
      'mimeType': mimeType,
      'videoSize': videoSize,
      'videoDurationMs': videoDurationMs,
      'thumbnailPath': thumbnailPath,
      'watchState': watchState.name,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  factory WatchSessionModel.fromMap(Map<String, dynamic> map) {
    return WatchSessionModel(
      watchSessionId: map['watchSessionId'] ?? '',
      chatSessionId: map['chatSessionId'] ?? '',
      hostUid: map['hostUid'] ?? '',
      viewerUid: map['viewerUid'] ?? '',
      videoName: map['videoName'] ?? '',
      mimeType: map['mimeType'] ?? '',
      videoSize: map['videoSize'] ?? 0,
      videoDurationMs: map['videoDurationMs'] ?? 0,
      thumbnailPath: map['thumbnailPath'],
      watchState: WatchState.values.firstWhere(
        (e) => e.name == map['watchState'],
        orElse: () => WatchState.waiting,
      ),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      startedAt: map['startedAt'] != null
          ? DateTime.parse(map['startedAt'])
          : null,
      endedAt: map['endedAt'] != null
          ? DateTime.parse(map['endedAt'])
          : null,
    );
  }

  WatchSessionModel copyWith({
    String? watchSessionId,
    String? chatSessionId,
    String? hostUid,
    String? viewerUid,
    String? videoName,
    String? mimeType,
    int? videoSize,
    int? videoDurationMs,
    String? thumbnailPath,
    WatchState? watchState,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return WatchSessionModel(
      watchSessionId: watchSessionId ?? this.watchSessionId,
      chatSessionId: chatSessionId ?? this.chatSessionId,
      hostUid: hostUid ?? this.hostUid,
      viewerUid: viewerUid ?? this.viewerUid,
      videoName: videoName ?? this.videoName,
      mimeType: mimeType ?? this.mimeType,
      videoSize: videoSize ?? this.videoSize,
      videoDurationMs: videoDurationMs ?? this.videoDurationMs,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      watchState: watchState ?? this.watchState,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}