import 'package:flutter/services.dart';

class NativePoseRepository {
  static const MethodChannel _channel = MethodChannel('pose_native');

  static Future<Map<String, dynamic>> runPoseEstimationOnImage(
    String imagePath, {
    String modelAssetName = 'pose_landmarker_lite',
  }) async {
    final result = await _channel.invokeMethod('runPoseEstimationOnImage', {
      'imagePath': imagePath,
      'modelAssetName': modelAssetName,
    });
    return Map<String, dynamic>.from(result);
  }
}
