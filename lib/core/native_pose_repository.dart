import 'package:flutter/services.dart';

class NativePoseRepository {
  static const MethodChannel _channel = MethodChannel('pose_native');

  static Future<Map<String, dynamic>> runPoseEstimationOnImage(
    String imagePath,
  ) async {
    final result = await _channel.invokeMethod('runPoseEstimationOnImage', {
      'imagePath': imagePath,
    });
    return Map<String, dynamic>.from(result);
  }
}
