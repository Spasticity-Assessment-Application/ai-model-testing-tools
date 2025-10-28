import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../core/native_pose_repository.dart';

class PoseRepository {
  bool _initialized = false;

  PoseRepository();

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  void dispose() {
    _initialized = false;
  }

  bool get isInitialized => _initialized;

  Future<PoseResult> analyzeVideoFrame(
    String videoPath, {
    int timeMs = 0,
  }) async {
    if (!_initialized) throw Exception('Pose model not initialized');

    final uint8list = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.PNG,
      timeMs: timeMs,
      quality: 75,
      maxWidth: 256,
      maxHeight: 256,
    );

    if (uint8list == null) {
      throw Exception('Failed to extract frame from video');
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/frame_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await tempFile.writeAsBytes(uint8list);

    try {
      final result = await NativePoseRepository.runPoseEstimationOnImage(
        tempFile.path,
      );
      final keypointsData = result['keypoints'] as List<dynamic>? ?? [];

      final keypoints = keypointsData.map((kp) {
        if (kp is Map) {
          return Keypoint(
            x: (kp['x'] as num?)?.toDouble() ?? 0.0,
            y: (kp['y'] as num?)?.toDouble() ?? 0.0,
            score: (kp['score'] as num?)?.toDouble() ?? 0.0,
          );
        }
        return Keypoint(x: 0.0, y: 0.0, score: 0.0);
      }).toList();

      await tempFile.delete();

      return PoseResult(keypoints: keypoints);
    } catch (e) {
      await tempFile.delete();
      throw Exception('Failed to run pose inference: $e');
    }
  }
}

class Keypoint {
  final double x; // normalized [0,1]
  final double y; // normalized [0,1]
  final double score;

  // Optional z (depth) for models that provide it (MediaPipe)
  final double? z;

  Keypoint({required this.x, required this.y, required this.score, this.z});
}

class PoseResult {
  final List<Keypoint> keypoints;
  PoseResult({required this.keypoints});
}
