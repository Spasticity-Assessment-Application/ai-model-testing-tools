import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/presentation/widgets/widgets.dart';
import '../../logic/pose_cubit.dart';
import '../../logic/pose_state.dart';
import '../../data/pose_model.dart';
import '../../data/tflite_pose_model.dart';
import '../widgets/widgets.dart';
import '../widgets/confidence_selector.dart';
import 'pose_results_page.dart';

class PoseSetupPage extends StatefulWidget {
  const PoseSetupPage({super.key});

  @override
  State<PoseSetupPage> createState() => _PoseSetupPageState();
}

class _PoseSetupPageState extends State<PoseSetupPage> {
  String? _videoPath;
  PoseModel? _selectedModel;
  int _desiredFrameCount = 30;
  double _confidenceThreshold = 0.5;
  PoseCubit? _cubit;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _selectedModel = TFLitePoseModel(
      modelAssetName: 'pose_model_mnv3l_float32',
    );
    _initializeCubit();
  }

  Future<void> _initializeCubit() async {
    if (_isInitializing) {
      developer.log(
        'PoseSetupPage: Already initializing',
        name: 'PoseSetupPage',
      );
      return;
    }

    developer.log(
      'PoseSetupPage: Starting cubit initialization',
      name: 'PoseSetupPage',
    );
    setState(() {
      _isInitializing = true;
    });

    _cubit = PoseCubit(poseModel: _selectedModel);
    await _cubit!.initialize();

    developer.log(
      'PoseSetupPage: Cubit state after init: ${_cubit!.state.runtimeType}',
      name: 'PoseSetupPage',
    );

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> _onModelChanged(PoseModel? model) async {
    setState(() {
      _selectedModel = model;
    });
    await _cubit?.close();
    await _initializeCubit();
  }

  void _onConfidenceChanged(double value) {
    setState(() {
      _confidenceThreshold = value;
    });
    _cubit?.setConfidenceThreshold(value);
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _videoPath = result.files.first.path;
      });
    }
  }

  Future<void> _startAnalysis() async {
    if (_videoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord sélectionner une vidéo'),
        ),
      );
      return;
    }

    if (_selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord sélectionner un modèle'),
        ),
      );
      return;
    }

    if (_cubit == null || _isInitializing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initialisation en cours, veuillez patienter...'),
        ),
      );
      return;
    }

    if (_cubit!.state is! PoseReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Échec de l\'initialisation: ${_cubit!.state.runtimeType}',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _cubit!,
          child: PoseResultsPage(
            videoPath: _videoPath!,
            analyzeFullVideo: true,
            desiredFrameCount: _desiredFrameCount,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration de l\'analyse de pose')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configurez votre analyse de pose',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Model Selection
            const Text(
              '1. Sélectionner le modèle IA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ModelSelector(
              selectedModel: _selectedModel,
              onModelChanged: _onModelChanged,
            ),
            const SizedBox(height: 24),

            // Confidence Threshold
            const Text(
              '2. Seuil de confiance des keypoints',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ConfidenceSelector(
              confidenceThreshold: _confidenceThreshold,
              onConfidenceChanged: _onConfidenceChanged,
            ),
            const SizedBox(height: 24),

            // Analysis Options
            const Text(
              '3. Options d\'analyse',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Wrap the entire analysis options section in GestureDetector
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Frame count configuration
                  const Text(
                    'Nombre de frames à analyser',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Frames: ', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: _desiredFrameCount.toString(),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            final count = int.tryParse(value);
                            if (count != null && count > 0 && count <= 100) {
                              setState(() {
                                _desiredFrameCount = count;
                              });
                            }
                          },
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).unfocus(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '(10-100 recommandé)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Video Selection
            const Text(
              '3. Sélectionner la vidéo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            AppActionButtonsWidget(
              buttons: [
                AppActionButton(
                  onPressed: _pickVideo,
                  icon: Icons.video_library,
                  label: 'Choisir une vidéo',
                  backgroundColor: Colors.purple,
                ),
              ],
              expandButtons: false,
              mainAxisAlignment: MainAxisAlignment.start,
            ),

            if (_videoPath != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vidéo sélectionnée : ${_videoPath!.split(Platform.pathSeparator).last}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Analysis Button
            const Text(
              '4. Démarrer l\'analyse',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            AppActionButtonsWidget(
              buttons: [
                AppActionButton(
                  onPressed: _startAnalysis,
                  icon: Icons.play_arrow,
                  label: 'Analyser les images vidéo',
                  backgroundColor: Colors.blue,
                ),
              ],
              expandButtons: false,
              mainAxisAlignment: MainAxisAlignment.start,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }
}
