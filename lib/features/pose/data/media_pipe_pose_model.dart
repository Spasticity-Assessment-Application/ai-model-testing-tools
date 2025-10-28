import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/native_pose_repository.dart';
import 'pose_model.dart';

/// Implémentation MediaPipe du modèle de pose
class MediaPipePoseModel implements PoseModel {
  @override
  String get name => 'MediaPipe Pose';

  @override
  String get description =>
      'Modèle MediaPipe pour l\'estimation de pose humaine';

  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Vérifier que le modèle est disponible dans les assets
    try {
      await rootBundle.load('assets/models/pose_landmarker_lite.task');
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
      // Créer un fichier temporaire pour l'image
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await tempFile.writeAsBytes(imageBytes);

      // Utiliser le repository natif pour l'analyse
      final result = await NativePoseRepository.runPoseEstimationOnImage(
        tempFile.path,
      );
      final nativeResult = Map<String, dynamic>.from(result);

      // Nettoyer le fichier temporaire
      await tempFile.delete();

      // Convertir le résultat natif en PoseResult
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
        imageWidth: 256, // Valeur par défaut, pourrait être calculée
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
