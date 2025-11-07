import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'pose_model.dart';

class TFLitePoseModel implements PoseModel {
  final String _modelAssetName;
  static const int _inputWidth = 192;
  static const int _inputHeight = 192;
  static const int _heatmapWidth = 48;
  static const int _heatmapHeight = 48;
  static const int _numKeypoints = 3;

  Interpreter? _interpreter;
  bool _isInitialized = false;
  int _originalImageWidth = 0;
  int _originalImageHeight = 0;

  TFLitePoseModel({String modelAssetName = 'pose_model_quantized'})
    : _modelAssetName = modelAssetName;

  @override
  String get name {
    switch (_modelAssetName) {
      case 'pose_model_dynamic':
        return 'TFLite Pose (Dynamic)';
      case 'pose_model_float16':
        return 'TFLite Pose (Float16)';
      case 'pose_model_float32':
        return 'TFLite Pose (Float32)';
      case 'pose_model_quantized':
      default:
        return 'TFLite Pose (Quantized)';
    }
  }

  @override
  String get description {
    switch (_modelAssetName) {
      case 'pose_model_dynamic':
        return 'TensorFlow Lite dynamic quantization model for hip, knee, and ankle detection';
      case 'pose_model_float16':
        return 'TensorFlow Lite Float16 precision model for hip, knee, and ankle detection';
      case 'pose_model_float32':
        return 'TensorFlow Lite Float32 precision model for hip, knee, and ankle detection';
      case 'pose_model_quantized':
      default:
        return 'TensorFlow Lite INT8 quantized model for hip, knee, and ankle detection';
    }
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/$_modelAssetName.tflite',
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to load TFLite model: $e');
    }
  }

  @override
  Future<PoseResult> analyzeImage(
    Uint8List imageBytes, {
    int? originalWidth,
    int? originalHeight,
  }) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('TFLite model not initialized');
    }

    try {
      final startTime = DateTime.now().millisecondsSinceEpoch;

      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Stocker les dimensions originales
      _originalImageWidth = originalWidth ?? image.width;
      _originalImageHeight = originalHeight ?? image.height;

      final resizedImage = img.copyResize(
        image,
        width: _inputWidth,
        height: _inputHeight,
      );

      final inputTensor = _imageToFloat32List(resizedImage);

      final outputHeatmaps = List.generate(
        1,
        (_) => List.generate(
          _heatmapHeight,
          (_) => List.generate(
            _heatmapWidth,
            (_) => List.filled(_numKeypoints, 0.0),
          ),
        ),
      );

      _interpreter!.run(inputTensor, outputHeatmaps);

      final keypoints = _extractKeypointsFromHeatmaps(outputHeatmaps[0]);

      final endTime = DateTime.now().millisecondsSinceEpoch;
      final analysisTimeMs = endTime - startTime;

      return PoseResult(
        keypoints: keypoints,
        imageWidth: _originalImageWidth,
        imageHeight: _originalImageHeight,
        modelName: name,
        analysisTimeMs: analysisTimeMs,
      );
    } catch (e) {
      throw Exception('TFLite pose analysis failed: $e');
    }
  }

  List<List<List<List<double>>>> _imageToFloat32List(img.Image image) {
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputHeight,
        (_) => List.generate(_inputWidth, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < _inputHeight; y++) {
      for (int x = 0; x < _inputWidth; x++) {
        final pixel = image.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    return input;
  }

  List<Keypoint> _extractKeypointsFromHeatmaps(
    List<List<List<double>>> heatmaps,
  ) {
    final keypoints = <Keypoint>[];

    for (int k = 0; k < _numKeypoints; k++) {
      double maxVal = 0.0;
      int maxX = 0;
      int maxY = 0;

      for (int y = 0; y < _heatmapHeight; y++) {
        for (int x = 0; x < _heatmapWidth; x++) {
          final value = heatmaps[y][x][k];
          if (value > maxVal) {
            maxVal = value;
            maxX = x;
            maxY = y;
          }
        }
      }

      // Conversion vers coordonnées image originale
      final pixelX = (maxX * _originalImageWidth) / _heatmapWidth;
      final pixelY = (maxY * _originalImageHeight) / _heatmapHeight;

      // Normaliser 0-1 par rapport à l'image originale
      final normalizedX = pixelX / _originalImageWidth;
      final normalizedY = pixelY / _originalImageHeight;

      keypoints.add(Keypoint(x: normalizedX, y: normalizedY, score: maxVal));
    }

    return keypoints;
  }

  @override
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
