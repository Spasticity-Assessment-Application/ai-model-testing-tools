import 'package:flutter/material.dart';
import '../../data/pose_model.dart';
import '../../data/media_pipe_pose_model.dart';

class ModelSelector extends StatefulWidget {
  final PoseModel? selectedModel;
  final ValueChanged<PoseModel?> onModelChanged;

  const ModelSelector({
    super.key,
    this.selectedModel,
    required this.onModelChanged,
  });

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  late PoseModel? _selectedModel;

  // List of available models
  final List<PoseModel> _availableModels = [
    MediaPipePoseModel(modelAssetName: 'pose_landmarker_lite'),
    MediaPipePoseModel(modelAssetName: 'pose_landmarker_full'),
    MediaPipePoseModel(modelAssetName: 'pose_landmarker_heavy'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.selectedModel ?? _availableModels.first;
  }

  @override
  void didUpdateWidget(ModelSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedModel != oldWidget.selectedModel) {
      _selectedModel = widget.selectedModel ?? _availableModels.first;
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
              'Sélection du modèle de pose',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._availableModels.map(
              (model) => RadioListTile<PoseModel>(
                title: Text(model.name),
                subtitle: Text(model.description),
                value: model,
                groupValue: _selectedModel,
                onChanged: (PoseModel? value) {
                  setState(() {
                    _selectedModel = value;
                  });
                  widget.onModelChanged(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
