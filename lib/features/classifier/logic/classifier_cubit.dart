import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/classifier_repository.dart';
import 'classifier_state.dart';

/// Cubit for managing image classification state
class ClassifierCubit extends Cubit<ClassifierState> {
  final ClassifierRepository _repository;

  ClassifierCubit({ClassifierRepository? repository})
    : _repository = repository ?? ClassifierRepository(),
      super(ClassifierInitial());

  /// Initialize the classification model
  Future<void> initializeModel() async {
    if (state is ClassifierReady) return;

    try {
      emit(ClassifierLoading());
      await _repository.initialize();
      emit(ClassifierReady());
    } catch (e) {
      emit(ClassifierError('Model initialization failed: ${e.toString()}'));
    }
  }

  /// Classify an image from file path
  Future<void> classifyImage(String imagePath) async {
    if (!_repository.isInitialized) {
      emit(ClassifierError('Model is not initialized', imagePath: imagePath));
      return;
    }

    try {
      emit(ClassifierClassifying());
      final result = await _repository.classifyImage(imagePath);
      emit(ClassifierResult(result: result, imagePath: imagePath));
    } catch (e) {
      emit(
        ClassifierError(
          'Classification failed: ${e.toString()}',
          imagePath: imagePath,
        ),
      );
    }
  }

  /// Reset to ready state
  void reset() {
    if (_repository.isInitialized) {
      emit(ClassifierReady());
    } else {
      emit(ClassifierInitial());
    }
  }

  /// Get model configuration info
  Map<String, dynamic> getModelInfo() {
    if (!_repository.isInitialized) {
      return {'initialized': false};
    }

    return {
      'initialized': true,
      'inputShape': _repository.inputShape,
      'numClasses': _repository.numClasses,
      'confidenceThreshold': _repository.confidenceThreshold,
    };
  }

  /// Set confidence threshold for filtering predictions
  void setConfidenceThreshold(double threshold) {
    if (_repository.isInitialized) {
      _repository.setConfidenceThreshold(threshold);
    }
  }

  /// Auto-optimize threshold based on classification results
  void optimizeThresholdFromResult(ClassificationResult result) {
    if (_repository.isInitialized) {
      _repository.autoAdjustThreshold(result);
    }
  }

  @override
  Future<void> close() async {
    _repository.dispose();
    return super.close();
  }
}
