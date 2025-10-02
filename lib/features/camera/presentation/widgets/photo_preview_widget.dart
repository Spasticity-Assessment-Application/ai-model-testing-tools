import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/camera_cubit.dart';
import '../../../../../core/presentation/widgets/widgets.dart';

class PhotoPreviewWidget extends StatelessWidget {
  final String imagePath;

  const PhotoPreviewWidget({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Photo preview
          AppImageDisplayWidget(
            imagePath: imagePath,
            isExpanded: true,
            showShadow: false,
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: AppActionButtonsWidget(
              padding: EdgeInsets.zero,
              isRounded: true,
              expandButtons: true,
              buttons: [
                AppActionButton(
                  onPressed: () {
                    context.read<CameraCubit>().retakePhoto();
                  },
                  icon: Icons.refresh,
                  label: 'Retake',
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                ),
                AppActionButton(
                  onPressed: () {
                    context.read<CameraCubit>().confirmPhoto(imagePath);
                  },
                  icon: Icons.check,
                  label: 'Use Photo',
                  backgroundColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
