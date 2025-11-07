import 'package:flutter/material.dart';

class ConfidenceSelector extends StatefulWidget {
  final double confidenceThreshold;
  final ValueChanged<double> onConfidenceChanged;

  const ConfidenceSelector({
    super.key,
    required this.confidenceThreshold,
    required this.onConfidenceChanged,
  });

  @override
  State<ConfidenceSelector> createState() => _ConfidenceSelectorState();
}

class _ConfidenceSelectorState extends State<ConfidenceSelector> {
  late double _currentConfidence;

  @override
  void initState() {
    super.initState();
    _currentConfidence = widget.confidenceThreshold;
  }

  @override
  void didUpdateWidget(ConfidenceSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.confidenceThreshold != oldWidget.confidenceThreshold) {
      _currentConfidence = widget.confidenceThreshold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seuil de confiance des keypoints',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Seuil minimum de confiance pour afficher un keypoint',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('0.0', style: Theme.of(context).textTheme.bodySmall),
                Expanded(
                  child: Slider(
                    value: _currentConfidence,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label: _currentConfidence.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        _currentConfidence = value;
                      });
                      widget.onConfidenceChanged(value);
                    },
                  ),
                ),
                Text('1.0', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Confiance actuelle: ${(_currentConfidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              _getConfidenceDescription(_currentConfidence),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getConfidenceDescription(double confidence) {
    if (confidence < 0.2) {
      return 'Très permissif - Beaucoup de keypoints détectés, mais moins précis';
    } else if (confidence < 0.4) {
      return 'Permissif - Bonne détection, quelques keypoints moins fiables';
    } else if (confidence < 0.6) {
      return 'Équilibré - Bon compromis précision/détection (recommandé)';
    } else if (confidence < 0.8) {
      return 'Strict - Seulement les keypoints très fiables';
    } else {
      return 'Très strict - Peu de keypoints, mais très précis';
    }
  }
}
