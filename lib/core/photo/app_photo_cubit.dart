import 'package:flutter_bloc/flutter_bloc.dart';

// State for sharing captured photos across the app
class AppPhotoState {
  final String? capturedPhotoPath;
  final DateTime? captureTime;

  AppPhotoState({
    this.capturedPhotoPath,
    this.captureTime,
  });

  AppPhotoState copyWith({
    String? capturedPhotoPath,
    DateTime? captureTime,
  }) {
    return AppPhotoState(
      capturedPhotoPath: capturedPhotoPath ?? this.capturedPhotoPath,
      captureTime: captureTime ?? this.captureTime,
    );
  }
}

// Cubit to manage global photo state
class AppPhotoCubit extends Cubit<AppPhotoState> {
  AppPhotoCubit() : super(AppPhotoState());

  void setCapturedPhoto(String imagePath) {
    emit(state.copyWith(
      capturedPhotoPath: imagePath,
      captureTime: DateTime.now(),
    ));
  }

  void clearCapturedPhoto() {
    emit(AppPhotoState());
  }

  String? get currentPhotoPath => state.capturedPhotoPath;
  DateTime? get captureTime => state.captureTime;
}