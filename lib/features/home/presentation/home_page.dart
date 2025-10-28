
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/photo/app_photo_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const cameraRoute = '/camera';
  static const photoDisplayRoute = '/photo-display';

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    context.read<AppPhotoCubit>().setCapturedPhoto(x.path);
    if (context.mounted) {
      context.push('/photo-display');
    }
  }

  void _openCamera(BuildContext context) => context.push(cameraRoute);

  void _openPosePage(BuildContext context) => context.push('/pose');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Évaluation de la spasticité')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppActionButtonsWidget(
            buttons: [
              AppActionButton(
                onPressed: () => _openCamera(context),
                icon: Icons.camera_alt,
                label: 'Prendre une photo',
                backgroundColor: Colors.orange,
              ),
              AppActionButton(
                onPressed: () => _pickFromGallery(context),
                icon: Icons.photo_library,
                label: 'Choisir une image',
                backgroundColor: Colors.green,
              ),
              AppActionButton(
                onPressed: () => _openPosePage(context),
                icon: Icons.video_label,
                label: 'Test pose',
                backgroundColor: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
