import 'dart:io';
import 'package:flutter/foundation.dart';
import 'camera_state.dart';

class MockCameraState {
  static bool get isSimulator {
    // On web or when debugging on simulator
    return kIsWeb || (kDebugMode && _isRunningOnSimulator());
  }
  
  static bool _isRunningOnSimulator() {
    // Simple detection based on environment
    return Platform.isIOS && kDebugMode;
  }
  
  static CameraState get mockCameraReadyState {
    return CameraInitial(); // Returns a simulated state
  }
}