class LocalVideoModel {
  /// Links this local video to a watch session.
  final String watchSessionId;

  /// Absolute local path on the host device.
  final String videoPath;

  /// Display name.
  final String videoName;

  /// MIME type.
  final String mimeType;

  /// File size in bytes.
  final int videoSize;

  /// Duration in milliseconds.
  final int videoDurationMs;

  /// Optional generated thumbnail path.
  final String? thumbnailPath;

  const LocalVideoModel({
    required this.watchSessionId,
    required this.videoPath,
    required this.videoName,
    required this.mimeType,
    required this.videoSize,
    required this.videoDurationMs,
    this.thumbnailPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'watchSessionId': watchSessionId,
      'videoPath': videoPath,
      'videoName': videoName,
      'mimeType': mimeType,
      'videoSize': videoSize,
      'videoDurationMs': videoDurationMs,
      'thumbnailPath': thumbnailPath,
    };
  }

  factory LocalVideoModel.fromMap(Map<String, dynamic> map) {
    return LocalVideoModel(
      watchSessionId: map['watchSessionId'] ?? '',
      videoPath: map['videoPath'] ?? '',
      videoName: map['videoName'] ?? '',
      mimeType: map['mimeType'] ?? '',
      videoSize: map['videoSize'] ?? 0,
      videoDurationMs: map['videoDurationMs'] ?? 0,
      thumbnailPath: map['thumbnailPath'],
    );
  }

  LocalVideoModel copyWith({
    String? watchSessionId,
    String? videoPath,
    String? videoName,
    String? mimeType,
    int? videoSize,
    int? videoDurationMs,
    String? thumbnailPath,
  }) {
    return LocalVideoModel(
      watchSessionId: watchSessionId ?? this.watchSessionId,
      videoPath: videoPath ?? this.videoPath,
      videoName: videoName ?? this.videoName,
      mimeType: mimeType ?? this.mimeType,
      videoSize: videoSize ?? this.videoSize,
      videoDurationMs: videoDurationMs ?? this.videoDurationMs,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}