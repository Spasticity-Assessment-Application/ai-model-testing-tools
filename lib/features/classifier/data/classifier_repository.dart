import 'dart:io';
import 'dart:typed_data';
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
  static const int _inputSize = 224; // MobileNetV2 input size
  static const int _numChannels = 3; // RGB
  static const double _threshold = 0.5; // Confidence threshold

  /// Initialize the model and load labels
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset(_modelPath);
      await _loadLabels();
      _isInitialized = true;
    } catch (e) {
      throw ClassifierException('Failed to initialize model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData.split('\n')
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
      final output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);
      
      _interpreter!.run(input, output);
      return _processResults(output[0]);
    } catch (e) {
      throw ClassifierException('Classification failed: $e');
    }
  }

  /// Preprocess image to MobileNetV2 format (224x224x3, normalized 0-1)
  Future<List<List<List<List<double>>>>> _preprocessImage(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw ClassifierException('Unable to decode image');
      }

      final resizedImage = img.copyResize(
        image, 
        width: _inputSize, 
        height: _inputSize,
      );

      final input = List.generate(
        1,
        (batch) => List.generate(
          _inputSize,
          (y) => List.generate(
            _inputSize,
            (x) => List.generate(
              _numChannels,
              (c) {
                final pixel = resizedImage.getPixel(x, y);
                switch (c) {
                  case 0:
                    return pixel.r / 255.0;
                  case 1:
                    return pixel.g / 255.0;
                  case 2:
                    return pixel.b / 255.0;
                  default:
                    return 0.0;
                }
              },
            ),
          ),
        ),
      );

      return input;
    } catch (e) {
      throw ClassifierException('Image preprocessing failed: $e');
    }
  }

  /// Process inference results and return top 5 predictions
  ClassificationResult _processResults(List<double> outputs) {
    if (_labels == null || outputs.isEmpty) {
      throw ClassifierException('Missing labels or outputs');
    }

    final predictions = <Prediction>[];
    
    for (int i = 0; i < outputs.length && i < _labels!.length; i++) {
      predictions.add(Prediction(
        label: _labels![i],
        confidence: outputs[i],
      ));
    }

    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    final topPredictions = predictions.take(5).toList();

    return ClassificationResult(
      predictions: topPredictions,
      processingTime: DateTime.now(),
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
}

class ClassificationResult {
  final List<Prediction> predictions;
  final DateTime processingTime;

  ClassificationResult({
    required this.predictions,
    required this.processingTime,
  });

  Prediction? get topPrediction => predictions.isNotEmpty ? predictions.first : null;

  List<Prediction> getConfidentPredictions(double threshold) {
    return predictions.where((p) => p.confidence >= threshold).toList();
  }

  @override
  String toString() {
    return 'ClassificationResult(${predictions.length} predictions, top: ${topPrediction?.label} (${(topPrediction?.confidence ?? 0).toStringAsFixed(3)}))';
  }
}

class Prediction {
  final String label;
  final double confidence;

  Prediction({
    required this.label,
    required this.confidence,
  });

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