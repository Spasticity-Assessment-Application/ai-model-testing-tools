import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/photo/app_photo_cubit.dart';
import '../../../../../core/presentation/widgets/widgets.dart';
import 'package:poc/features/classifier/classifier.dart';

class PhotoActionsWidget extends StatelessWidget {
  final DateTime? captureTime;

  const PhotoActionsWidget({super.key, this.captureTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (captureTime != null)
            Text(
              'Capturé : ${captureTime!.toString().substring(0, 19)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          const SizedBox(height: 16),
          AppActionButtonsWidget(
            buttons: [
              AppActionButton(
                onPressed: () {
                  // Clear current photo and go back to camera
                  context.read<AppPhotoCubit>().clearCapturedPhoto();
                  context.pushReplacement('/camera');
                },
                icon: Icons.camera_alt,
                label: 'Reprendre la photo',
                backgroundColor: Colors.orange,
              ),
              AppActionButton(
                onPressed: () {
                  final photoPath = context
                      .read<AppPhotoCubit>()
                      .currentPhotoPath;
                  if (photoPath == null) return;

                  final cubit = context.read<ClassifierCubit>();

                  // 1) lancer la classification
                  cubit.classifyImage(photoPath);
                  //if (context.mounted) context.push('/result');
                  //j'ai juste mit des valeurs randoms pour tester
                  //context.read<AppPhotoCubit>().analyzePhoto("Classe A", 0.87);
                  context.push('/result');
                },
                icon: Icons.analytics,
                label: 'Analyser la photo',
                backgroundColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
