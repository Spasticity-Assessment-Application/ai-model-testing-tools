import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/photo/app_photo_cubit.dart';
import '../widgets/widgets.dart';

class PhotoDisplayPage extends StatelessWidget {
  const PhotoDisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captured Photo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: BlocBuilder<AppPhotoCubit, AppPhotoState>(
        builder: (context, state) {
          // If no photo, redirect to camera
          if (state.capturedPhotoPath == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.pushReplacement('/camera');
            });
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Photo display widget
              PhotoDisplayWidget(imagePath: state.capturedPhotoPath!),
              
              // Photo actions widget
              PhotoActionsWidget(captureTime: state.captureTime),
            ],
          );
        },
      ),
    );
  }
}