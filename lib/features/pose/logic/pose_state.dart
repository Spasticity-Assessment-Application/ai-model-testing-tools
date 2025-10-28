import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../data/pose_model.dart';

abstract class PoseState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PoseInitial extends PoseState {}

class PoseLoading extends PoseState {}

class PoseReady extends PoseState {}

class PoseResultState extends PoseState {
  final PoseResult result;
  final String sourcePath;
  final int imageWidth;
  final int imageHeight;

  PoseResultState({
    required this.result,
    required this.sourcePath,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  List<Object?> get props => [result, sourcePath, imageWidth, imageHeight];

  @override
  String toString() =>
      'PoseResultState(path: $sourcePath, keypoints: ${result.keypoints.length})';
}

class PoseVideoAnalysisState extends PoseState {
  final List<PoseResult> frameResults;
  final List<Uint8List> frameImages;
  final List<int> frameWidths;
  final List<int> frameHeights;
  final String sourcePath;
  final int currentFrameIndex;
  final bool isPlaying;

  PoseVideoAnalysisState({
    required this.frameResults,
    required this.frameImages,
    required this.frameWidths,
    required this.frameHeights,
    required this.sourcePath,
    required this.currentFrameIndex,
    required this.isPlaying,
  });

  @override
  List<Object?> get props => [
    frameResults,
    frameImages,
    frameWidths,
    frameHeights,
    sourcePath,
    currentFrameIndex,
    isPlaying,
  ];

  @override
  String toString() =>
      'PoseVideoAnalysisState(path: $sourcePath, frames: ${frameResults.length}, current: $currentFrameIndex, playing: $isPlaying)';
}

class PoseError extends PoseState {
  final String message;

  PoseError(this.message);

  @override
  List<Object?> get props => [message];
}
