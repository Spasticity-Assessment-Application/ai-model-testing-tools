import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/native_pose_repository.dart';
import 'pose_model.dart';

/// MediaPipe pose model implementation
class MediaPipePoseModel implements PoseModel {
  final String _modelAssetName;

  MediaPipePoseModel({String modelAssetName = 'pose_landmarker_lite'})
    : _modelAssetName = modelAssetName;

  @override
  String get name => 'MediaPipe Pose (${_modelAssetName.split('_').last})';

  @override
  String get description {
    switch (_modelAssetName) {
      case 'pose_landmarker_lite':
        return 'MediaPipe lightweight pose estimation model';
      case 'pose_landmarker_full':
        return 'MediaPipe full pose estimation model';
      case 'pose_landmarker_heavy':
        return 'MediaPipe high-precision pose estimation model';
      default:
        return 'MediaPipe pose estimation model';
    }
  }

  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await rootBundle.load('assets/models/$_modelAssetName.task');
      _isInitialized = true;
    } catch (e) {
      throw Exception('MediaPipe model not found in assets: $e');
    }
  }

  @override
  Future<PoseResult> analyzeImage(Uint8List imageBytes) async {
    if (!_isInitialized) {
      throw Exception('MediaPipe model not initialized');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(imageBytes);
      final result = await NativePoseRepository.runPoseEstimationOnImage(
        tempFile.path,
        modelAssetName: _modelAssetName,
      );
      final nativeResult = Map<String, dynamic>.from(result);
      await tempFile.delete();
      final keypoints = nativeResult['keypoints'] as List<dynamic>? ?? [];
      return PoseResult(
        keypoints: keypoints.map((kp) {
          final map = Map<String, dynamic>.from(kp as Map);
          return Keypoint(
            x: (map['x'] as num?)?.toDouble() ?? 0.0,
            y: (map['y'] as num?)?.toDouble() ?? 0.0,
            score: (map['score'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList(),
        imageWidth: 256,
        imageHeight: 256,
        modelName: name,
      );
    } catch (e) {
      throw Exception('MediaPipe pose analysis failed: $e');
    }
  }

  @override
  void dispose() {
    _isInitialized = false;
  }
}
