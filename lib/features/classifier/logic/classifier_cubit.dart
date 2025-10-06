import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/classifier_repository.dart';
import 'classifier_state.dart';

/// Cubit for managing image classification with MobileNetV2
class ClassifierCubit extends Cubit<ClassifierState> {
  final ClassifierRepository _repository;

  ClassifierCubit({ClassifierRepository? repository})
      : _repository = repository ?? ClassifierRepository(),
        super(ClassifierInitial());

  Future<void> initializeModel() async {
    if (state is ClassifierReady) {
      return;
    }

    try {
      emit(ClassifierLoading());
      await _repository.initialize();
      emit(ClassifierReady());
    } catch (e) {
      emit(ClassifierError('Model initialization failed: ${e.toString()}'));
    }
  }

  Future<void> classifyImage(String imagePath) async {
    if (!_repository.isInitialized) {
      emit(ClassifierError('Model is not initialized', imagePath: imagePath));
      return;
    }

    try {
      emit(ClassifierClassifying());
      
      final result = await _repository.classifyImage(imagePath);
      
      emit(ClassifierResult(
        result: result,
        imagePath: imagePath,
      ));
    } catch (e) {
      emit(ClassifierError(
        'Classification failed: ${e.toString()}',
        imagePath: imagePath,
      ));
    }
  }

  void reset() {
    if (_repository.isInitialized) {
      emit(ClassifierReady());
    } else {
      emit(ClassifierInitial());
    }
  }

  Map<String, dynamic> getModelInfo() {
    if (!_repository.isInitialized) {
      return {'initialized': false};
    }

    return {
      'initialized': true,
      'inputShape': _repository.inputShape,
      'numClasses': _repository.numClasses,
    };
  }

  @override
  Future<void> close() async {
    _repository.dispose();
    return super.close();
  }
}