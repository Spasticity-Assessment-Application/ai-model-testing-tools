import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/photo/app_photo_cubit.dart';
import 'camera_state.dart';

class CameraCubit extends Cubit<CameraState> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  final AppPhotoCubit? _appPhotoCubit;

  CameraCubit({AppPhotoCubit? appPhotoCubit})
    : _appPhotoCubit = appPhotoCubit,
      super(CameraInitial());

  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;

  Future<void> initializeCamera() async {
    try {
      emit(CameraLoading());

      // Get available cameras - this automatically triggers permission request on iOS
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        emit(
          CameraError(
            'No camera available. Please test on a physical device with camera.',
          ),
        );
        return;
      }

      // Initialize controller with first camera
      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      emit(CameraReady(controller: _controller!, cameras: _cameras));
    } catch (e) {
      // Handle permission denied or other errors
      String errorMessage = e.toString();
      if (errorMessage.contains('Permission') ||
          errorMessage.contains('denied')) {
        emit(
          CameraError(
            'Camera permission denied. Please grant camera access when prompted or check device settings.',
          ),
        );
      } else {
        emit(CameraError('Error initializing camera: $e'));
      }
    }
  }

  Future<void> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      emit(CameraError('Camera is not initialized'));
      return;
    }

    try {
      emit(PhotoSaving());

      // Take the photo
      final XFile photo = await _controller!.takePicture();

      // Show preview with the temporary path
      emit(PhotoTakenPreview(photo.path));
    } catch (e) {
      emit(CameraError('Error taking photo: $e'));
    }
  }

  Future<void> confirmPhoto(String tempPath) async {
    try {
      emit(PhotoSaving());

      // Get app cache directory (not user's photos)
      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String cachedImagePath =
          '${tempDir.path}/captured_photo_$timestamp.jpg';

      // Copy file to app cache
      await File(tempPath).copy(cachedImagePath);

      // Delete original temporary file
      await File(tempPath).delete();

      // Notify global app state
      _appPhotoCubit?.setCapturedPhoto(cachedImagePath);

      emit(PhotoSaved(cachedImagePath));
    } catch (e) {
      emit(CameraError('Error saving photo: $e'));
    }
  }

  Future<void> retakePhoto() async {
    try {
      // Delete temporary file if it exists
      if (state is PhotoTakenPreview) {
        final tempPath = (state as PhotoTakenPreview).imagePath;
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      // Return to camera ready state
      if (_controller != null && _controller!.value.isInitialized) {
        emit(CameraReady(controller: _controller!, cameras: _cameras));
      } else {
        await initializeCamera();
      }
    } catch (e) {
      emit(CameraError('Error returning to camera: $e'));
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2 || _controller == null) {
      return;
    }

    try {
      emit(CameraLoading());

      // Find next camera
      final currentCamera = _controller!.description;
      final nextCameraIndex =
          (_cameras.indexOf(currentCamera) + 1) % _cameras.length;
      final nextCamera = _cameras[nextCameraIndex];

      // Dispose old controller
      await _controller!.dispose();

      // Create new controller with new camera
      _controller = CameraController(
        nextCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      emit(CameraReady(controller: _controller!, cameras: _cameras));
    } catch (e) {
      emit(CameraError('Error switching camera: $e'));
    }
  }

  @override
  Future<void> close() async {
    await _controller?.dispose();
    return super.close();
  }
}
