import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/camera_cubit.dart';

class CameraErrorWidget extends StatelessWidget {
  final String message;

  const CameraErrorWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => context.read<CameraCubit>().initializeCamera(),
                child: const Text('Réessayer'),
              ),
              if (message.contains('permanently denied') ||
                  message.contains('settings'))
                const SizedBox(width: 16),
              if (message.contains('permanently denied') ||
                  message.contains('settings'))
                ElevatedButton(
                  onPressed: () {
                    // Simple retry for now
                    context.read<CameraCubit>().initializeCamera();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Réessayer les permissions'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
