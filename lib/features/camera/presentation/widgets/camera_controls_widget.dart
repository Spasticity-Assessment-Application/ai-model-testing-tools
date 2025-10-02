import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/camera_cubit.dart';
import '../../logic/camera_state.dart';

class CameraControlsWidget extends StatelessWidget {
  final CameraState state;

  const CameraControlsWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is! CameraReady) {
      return const SizedBox.shrink();
    }

    final cameraState = state as CameraReady;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Button to switch camera
            if (cameraState.cameras.length > 1)
              FloatingActionButton(
                heroTag: "switch_camera",
                onPressed: () => context.read<CameraCubit>().switchCamera(),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(Icons.switch_camera, color: Colors.white),
              )
            else
              const SizedBox(width: 56),

            // Button to take photo
            FloatingActionButton.large(
              heroTag: "take_picture",
              onPressed: state is PhotoSaving
                  ? null
                  : () => context.read<CameraCubit>().takePicture(),
              backgroundColor: Colors.white,
              child: state is PhotoSaving
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.camera_alt, color: Colors.black, size: 32),
            ),

            // Space to maintain symmetry
            const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }
}
