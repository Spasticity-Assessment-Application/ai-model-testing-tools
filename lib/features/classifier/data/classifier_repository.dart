import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Repository for managing MobileNetV2 model and image classification
class ClassifierRepository {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;

  // MobileNetV2 configuration
  static const String _modelPath = 'assets/models/mobilenet_v2.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';

  // Input size MUST match the model's expected input
  // MobileNetV2 was trained on 224x224 images
  static const int _inputSize = 224; // MobileNetV2 fixed input size
  static const int _numChannels = 3; // RGB

  double _threshold = 0.5; // 50% confidence threshold

  /// Initialize the model and load labels
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      await _loadLabels();
      _validateModelConfiguration();
      _isInitialized = true;
    } catch (e) {
      throw ClassifierException('Failed to initialize model: $e');
    }
  }

  /// Validate model configuration matches expected dimensions
  void _validateModelConfiguration() {
    if (_interpreter == null) return;

    final inputTensor = _interpreter!.getInputTensor(0);
    if (inputTensor.shape.length >= 3) {
      final modelInputHeight = inputTensor.shape[1];
      final modelInputWidth = inputTensor.shape[2];

      if (modelInputHeight != _inputSize || modelInputWidth != _inputSize) {
        throw ClassifierException(
          'Input size mismatch: Expected ${_inputSize}x$_inputSize, '
          'Model requires ${modelInputHeight}x$modelInputWidth',
        );
      }
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();
    } catch (e) {
      throw ClassifierException('Failed to load labels: $e');
    }
  }

  /// Classify an image from its file path
  Future<ClassificationResult> classifyImage(String imagePath) async {
    if (!_isInitialized) {
      throw ClassifierException('Model is not initialized');
    }

    try {
      final imageData = await _preprocessImage(imagePath);

      final input = [imageData];
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final output = List.generate(
        outputShape[0],
        (batch) => List.filled(outputShape[1], 0),
      );

      _interpreter!.run(input, output);

      return _processResults(output[0]);
    } catch (e) {
      throw ClassifierException('Classification failed: $e');
    }
  }

  /// Preprocess image to MobileNetV2 format (224x224x3, uint8 values 0-255)
  Future<List<List<List<int>>>> _preprocessImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();

      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw ClassifierException('Unable to decode image');
      }

      // Resize to model input size
      final resizedImage = img.copyResize(
        image,
        width: _inputSize,
        height: _inputSize,
      );

      // Convert to tensor format (RGB uint8 values)
      return List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) => List.generate(_numChannels, (c) {
            final pixel = resizedImage.getPixel(x, y);
            switch (c) {
              case 0:
                return pixel.r.toInt();
              case 1:
                return pixel.g.toInt();
              case 2:
                return pixel.b.toInt();
              default:
                return 0;
            }
          }),
        ),
      );
    } catch (e) {
      throw ClassifierException('Image preprocessing failed: $e');
    }
  }

  /// Process inference results and return top predictions
  ClassificationResult _processResults(List<int> outputs) {
    if (_labels == null || outputs.isEmpty) {
      throw ClassifierException('Missing labels or outputs');
    }

    final allPredictions = <Prediction>[];

    for (int i = 0; i < outputs.length && i < _labels!.length; i++) {
      final confidence = outputs[i] / 255.0;
      allPredictions.add(
        Prediction(label: _labels![i], confidence: confidence),
      );
    }

    allPredictions.sort((a, b) => b.confidence.compareTo(a.confidence));

    final confidentPredictions = allPredictions
        .where((p) => p.confidence >= _threshold)
        .toList();

    final topPredictions = confidentPredictions.isNotEmpty
        ? confidentPredictions.take(5).toList()
        : allPredictions.take(5).toList();

    return ClassificationResult(
      predictions: topPredictions,
      processingTime: DateTime.now(),
      isHighQuality: confidentPredictions.isNotEmpty,
      confidenceThreshold: _threshold,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;

  List<int> get inputShape => [1, _inputSize, _inputSize, _numChannels];

  int get numClasses => _labels?.length ?? 0;

  double get confidenceThreshold => _threshold;

  /// Set confidence threshold for filtering predictions
  void setConfidenceThreshold(double threshold) {
    if (threshold < 0.0 || threshold > 1.0) {
      throw ArgumentError('Threshold must be between 0.0 and 1.0');
    }
    _threshold = threshold;
  }

  /// Auto-adjust threshold based on classification results
  void autoAdjustThreshold(ClassificationResult result) {
    if (result.predictions.isEmpty) return;

    final topConfidence = result.topPrediction?.confidence ?? 0.0;
    final avgTopConfidence =
        result.predictions
            .take(3)
            .map((p) => p.confidence)
            .reduce((a, b) => a + b) /
        3;

    if (topConfidence > 0.8 && avgTopConfidence > 0.6) {
      setConfidenceThreshold(0.6);
    } else if (topConfidence > 0.6 && avgTopConfidence > 0.4) {
      setConfidenceThreshold(0.4);
    } else {
      setConfidenceThreshold(0.2);
    }
  }
}

class ClassificationResult {
  final List<Prediction> predictions;
  final DateTime processingTime;
  final bool isHighQuality;
  final double confidenceThreshold;

  ClassificationResult({
    required this.predictions,
    required this.processingTime,
    this.isHighQuality = false,
    this.confidenceThreshold = 0.5,
  });

  Prediction? get topPrediction =>
      predictions.isNotEmpty ? predictions.first : null;

  List<Prediction> getConfidentPredictions(double threshold) {
    return predictions.where((p) => p.confidence >= threshold).toList();
  }

  /// Returns true if the top prediction is above the confidence threshold
  bool get isReliable =>
      topPrediction != null && topPrediction!.confidence >= confidenceThreshold;

  /// Gets a quality indicator string
  String get qualityIndicator {
    if (!isHighQuality) {
      return "Low confidence";
    }
    if (topPrediction != null && topPrediction!.confidence >= 0.8) {
      return "High confidence";
    }
    if (topPrediction != null && topPrediction!.confidence >= 0.6) {
      return "Medium confidence";
    }
    return "Acceptable confidence";
  }

  @override
  String toString() {
    return 'ClassificationResult(${predictions.length} predictions, top: ${topPrediction?.label} (${(topPrediction?.confidence ?? 0).toStringAsFixed(3)}))';
  }
}

class Prediction {
  final String label;
  final double confidence;

  Prediction({required this.label, required this.confidence});

  double get confidencePercentage => confidence * 100;

  @override
  String toString() {
    return '$label: ${confidencePercentage.toStringAsFixed(1)}%';
  }
}

class ClassifierException implements Exception {
  final String message;

  ClassifierException(this.message);

  @override
  String toString() => 'ClassifierException: $message';
}
