import 'package:flutter/material.dart';
import '../../../../../core/presentation/widgets/widgets.dart';

class PhotoDisplayWidget extends StatelessWidget {
  final String imagePath;

  const PhotoDisplayWidget({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return AppImageDisplayWidget(
      imagePath: imagePath,
      isExpanded: true,
      showShadow: true,
    );
  }
}
