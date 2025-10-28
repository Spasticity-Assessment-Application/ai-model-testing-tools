import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppImageDisplayWidget extends StatelessWidget {
  final String? imagePath;
  final Uint8List? imageBytes;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double borderRadius;
  final bool showShadow;
  final bool isExpanded;
  final BoxFit fit;

  const AppImageDisplayWidget({
    super.key,
    this.imagePath,
    this.imageBytes,
    this.margin,
    this.padding,
    this.borderRadius = 12.0,
    this.showShadow = true,
    this.isExpanded = true,
    this.fit = BoxFit.contain,
  }) : assert(
         imagePath != null || imageBytes != null,
         'Either imagePath or imageBytes must be provided',
       );

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageBytes != null) {
      imageWidget = Image.memory(imageBytes!, fit: fit);
    } else {
      imageWidget = Image.file(File(imagePath!), fit: fit);
    }

    Widget imageContainer = Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.all(16),
      padding: padding,
      decoration: showShadow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : BoxDecoration(borderRadius: BorderRadius.circular(borderRadius)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      ),
    );

    return isExpanded ? Expanded(child: imageContainer) : imageContainer;
  }
}
