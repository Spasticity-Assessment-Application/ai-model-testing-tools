import 'package:equatable/equatable.dart';
import '../data/classifier_repository.dart';

abstract class ClassifierState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ClassifierInitial extends ClassifierState {}

class ClassifierLoading extends ClassifierState {}

class ClassifierReady extends ClassifierState {}

class ClassifierClassifying extends ClassifierState {}

class ClassifierResult extends ClassifierState {
  final ClassificationResult result;
  final String imagePath;

  ClassifierResult({required this.result, required this.imagePath});

  @override
  List<Object?> get props => [result, imagePath];
}

class ClassifierError extends ClassifierState {
  final String message;
  final String? imagePath;

  ClassifierError(this.message, {this.imagePath});

  @override
  List<Object?> get props => [message, imagePath];
}
