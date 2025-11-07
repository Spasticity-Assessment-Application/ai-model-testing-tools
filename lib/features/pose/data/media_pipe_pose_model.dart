import 'dart:typed_data';
import 'pose_model.dart';

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
        return 'MediaPipe lightweight pose estimation model (NOT AVAILABLE - Native code removed)';
      case 'pose_landmarker_full':
        return 'MediaPipe full pose estimation model (NOT AVAILABLE - Native code removed)';
      case 'pose_landmarker_heavy':
        return 'MediaPipe high-precision pose estimation model (NOT AVAILABLE - Native code removed)';
      default:
        return 'MediaPipe pose estimation model (NOT AVAILABLE - Native code removed)';
    }
  }

  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    throw Exception(
      'MediaPipe models are no longer supported. Please use TFLite models instead.',
    );
  }

  @override
  Future<PoseResult> analyzeImage(
    Uint8List imageBytes, {
    int? originalWidth,
    int? originalHeight,
  }) async {
    throw Exception(
      'MediaPipe models are no longer supported. Please use TFLite models instead.',
    );
  }

  @override
  void dispose() {
    _isInitialized = false;
  }
}
