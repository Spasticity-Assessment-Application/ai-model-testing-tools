import 'package:video_thumbnail/video_thumbnail.dart';
import 'pose_model.dart';

class PoseRepository {
  final PoseModel _poseModel;
  bool _initialized = false;

  PoseRepository(this._poseModel);

  Future<void> initialize() async {
    if (_initialized) return;

    await _poseModel.initialize();
    _initialized = true;
  }

  void dispose() {
    _poseModel.dispose();
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

    return await _poseModel.analyzeImage(uint8list);
  }
}
