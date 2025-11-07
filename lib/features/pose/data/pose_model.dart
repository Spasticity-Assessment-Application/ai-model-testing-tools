import 'dart:typed_data';

abstract class PoseModel {
  /// Model name
  String get name;

  /// Model description
  String get description;

  /// Initializes the model
  Future<void> initialize();

  /// Analyzes an image and returns keypoints
  Future<PoseResult> analyzeImage(
    Uint8List imageBytes, {
    int? originalWidth,
    int? originalHeight,
  });

  /// Releases model resources
  void dispose();

  /// Checks if the model is initialized
  bool get isInitialized;
}

/// Result of a pose analysis
class PoseResult {
  final List<Keypoint> keypoints;
  final int imageWidth;
  final int imageHeight;
  final String modelName;
  final int analysisTimeMs;

  PoseResult({
    required this.keypoints,
    required this.imageWidth,
    required this.imageHeight,
    required this.modelName,
    required this.analysisTimeMs,
  });

  @override
  String toString() =>
      'PoseResult(model: $modelName, keypoints: ${keypoints.length}, size: ${imageWidth}x$imageHeight, time: ${analysisTimeMs}ms)';
}

/// Keypoint of a pose
class Keypoint {
  final double x;
  final double y;
  final double score;

  Keypoint({required this.x, required this.y, required this.score});

  @override
  String toString() => 'Keypoint(x: $x, y: $y, score: $score)';
}
