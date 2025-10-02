import 'dart:io';
import 'package:flutter/material.dart';

class AppImageDisplayWidget extends StatelessWidget {
  final String imagePath;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double borderRadius;
  final bool showShadow;
  final bool isExpanded;
  final BoxFit fit;

  const AppImageDisplayWidget({
    super.key,
    required this.imagePath,
    this.margin,
    this.padding,
    this.borderRadius = 12.0,
    this.showShadow = true,
    this.isExpanded = true,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
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
          : BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(imagePath),
          fit: fit,
        ),
      ),
    );

    return isExpanded ? Expanded(child: imageContainer) : imageContainer;
  }
}