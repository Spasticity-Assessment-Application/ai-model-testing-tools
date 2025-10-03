import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

abstract class CameraState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CameraInitial extends CameraState {}

class CameraLoading extends CameraState {}

class CameraReady extends CameraState {
  final CameraController controller;
  final List<CameraDescription> cameras;

  CameraReady({
    required this.controller,
    required this.cameras,
  });

  @override
  List<Object?> get props => [controller, cameras];
}

class CameraError extends CameraState {
  final String message;

  CameraError(this.message);

  @override
  List<Object?> get props => [message];
}

class PhotoTaken extends CameraState {
  final String imagePath;

  PhotoTaken(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class PhotoSaving extends CameraState {}

class PhotoTakenPreview extends CameraState {
  final String imagePath;

  PhotoTakenPreview(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class PhotoSaved extends CameraState {
  final String imagePath;

  PhotoSaved(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}