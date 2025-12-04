import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'pose_model.dart';

class TFLitePoseModel implements PoseModel {
  final String _modelAssetName;
  late final int _inputWidth;
  late final int _inputHeight;
  late final int _heatmapWidth;
  late final int _heatmapHeight;
  static const int _numKeypoints = 3;

  Interpreter? _interpreter;
  bool _isInitialized = false;
  int _originalImageWidth = 0;
  int _originalImageHeight = 0;

  TFLitePoseModel({String modelAssetName = 'pose_model_mnv3l_float32'})
    : _modelAssetName = modelAssetName {
    if (modelAssetName == 'pose_model_mnv3s_float32') {
      _inputWidth = 256;
      _inputHeight = 256;
      _heatmapWidth = 64;
      _heatmapHeight = 64;
    } else {
      _inputWidth = 384;
      _inputHeight = 384;
      _heatmapWidth = 96;
      _heatmapHeight = 96;
    }
  }

  @override
  String get name {
    switch (_modelAssetName) {
      case 'pose_model_mnv3l_float32':
        return 'MobileNetV3-Large (Float32)';
      case 'pose_model_mnv3s_float32':
        return 'MobileNetV3-Small (Float32)';
      default:
        return 'TFLite Pose Model';
    }
  }

  @override
  String get description {
    switch (_modelAssetName) {
      case 'pose_model_mnv3l_float32':
        return 'MobileNetV3-Large Float32 (384x384, 96x96 heatmap) - Hanche, Genoux, Cheville';
      case 'pose_model_mnv3s_float32':
        return 'MobileNetV3-Small Float32 (256x256, 64x64 heatmap) - Hanche, Genoux, Cheville';
      default:
        return 'TensorFlow Lite pose detection model - Hanche, Genoux, Cheville';
    }
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log(
        'TFLitePoseModel: Already initialized',
        name: 'TFLitePoseModel',
      );
      return;
    }

    try {
      developer.log(
        'TFLitePoseModel: Loading model from assets/models/$_modelAssetName.tflite',
        name: 'TFLitePoseModel',
      );
      _interpreter = await Interpreter.fromAsset(
        'assets/models/$_modelAssetName.tflite',
      );
      _isInitialized = true;
      developer.log(
        'TFLitePoseModel: Model loaded successfully',
        name: 'TFLitePoseModel',
      );
    } catch (e, stackTrace) {
      developer.log(
        'TFLitePoseModel: Failed to load model',
        name: 'TFLitePoseModel',
        error: e,
        stackTrace: stackTrace,
      );
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
