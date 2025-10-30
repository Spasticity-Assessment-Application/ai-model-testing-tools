import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../core/presentation/widgets/widgets.dart';
import '../../logic/pose_cubit.dart';
import '../../logic/pose_state.dart';
import '../../data/pose_model.dart';

class PoseResultsPage extends StatefulWidget {
  final String videoPath;
  final bool analyzeFullVideo;
  final int? desiredFrameCount;

  const PoseResultsPage({
    super.key,
    required this.videoPath,
    this.analyzeFullVideo = false,
    this.desiredFrameCount,
  });

  @override
  State<PoseResultsPage> createState() => _PoseResultsPageState();
}

enum KeypointDisplayMode { all, rightLeg, leftLeg }

class _PoseResultsPageState extends State<PoseResultsPage> {
  Uint8List? _thumbnailBytes;
  KeypointDisplayMode _displayMode = KeypointDisplayMode.all;
  late PoseCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<PoseCubit>();
    _loadThumbnail();
    _startAnalysis();
  }

  Future<void> _loadThumbnail() async {
    final bytes = await VideoThumbnail.thumbnailData(
      video: widget.videoPath,
      imageFormat: ImageFormat.PNG,
      timeMs: 0,
      quality: 75,
      maxWidth: 256,
      maxHeight: 256,
    );
    setState(() {
      _thumbnailBytes = bytes;
    });
  }

  Future<void> _startAnalysis() async {
    await _cubit.analyzeVideoFrames(
      widget.videoPath,
      analyzeFullVideo: widget.analyzeFullVideo,
      frameCount: widget.desiredFrameCount,
    );
  }

  @override
  void dispose() {
    // Stop playback when leaving the page
    if (_cubit.state is PoseVideoAnalysisState) {
      _cubit.togglePlayback();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats de l\'analyse de pose'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                'Analyse en cours : ${widget.videoPath.split('/').last}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),

            // Display mode selector
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const Text('Mode d\'affichage :'),
                SegmentedButton<KeypointDisplayMode>(
                  segments: const [
                    ButtonSegment(
                      value: KeypointDisplayMode.all,
                      label: Text('Tout'),
                    ),
                    ButtonSegment(
                      value: KeypointDisplayMode.rightLeg,
                      label: Text('Jambe droite'),
                    ),
                    ButtonSegment(
                      value: KeypointDisplayMode.leftLeg,
                      label: Text('Jambe gauche'),
                    ),
                  ],
                  selected: {_displayMode},
                  onSelectionChanged: (Set<KeypointDisplayMode> selected) {
                    setState(() {
                      _displayMode = selected.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Results display
            Expanded(
              child: BlocConsumer<PoseCubit, PoseState>(
                listener: (context, state) {
                  if (state is PoseResultState && _thumbnailBytes == null) {
                    _loadThumbnail();
                  }
                },
                builder: (context, state) {
                  return _buildContentForState(state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentForState(PoseState state) {
    if (state is PoseLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyse des images vidéo...'),
          ],
        ),
      );
    }

    if (state is PoseError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Échec de l\'analyse : ${state.message}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            AppActionButtonsWidget(
              buttons: [
                AppActionButton(
                  onPressed: _startAnalysis,
                  icon: Icons.refresh,
                  label: 'Réessayer',
                  backgroundColor: Colors.red,
                ),
              ],
              expandButtons: false,
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ],
        ),
      );
    }

    if (state is PoseVideoAnalysisState) {
      return _buildVideoAnalysisView(state);
    }

    if (state is PoseResultState) {
      return _buildSingleFrameView(state);
    }

    return const Center(
      child: Text('Sélectionnez une vidéo pour commencer l\'analyse'),
    );
  }

  Widget _buildSingleFrameView(PoseResultState state) {
    if (_thumbnailBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Stack(
              children: [
                AppImageDisplayWidget(
                  imageBytes: _thumbnailBytes,
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  isExpanded: false,
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _KeypointPainter(
                      state.result.keypoints,
                      state.imageWidth,
                      state.imageHeight,
                      _displayMode,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Found ${state.result.keypoints.length} keypoints',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildVideoAnalysisView(PoseVideoAnalysisState state) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Stack(
              children: [
                Image.memory(state.frameImages[state.currentFrameIndex]),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _KeypointPainter(
                      state.frameResults[state.currentFrameIndex].keypoints,
                      state.frameWidths[state.currentFrameIndex],
                      state.frameHeights[state.currentFrameIndex],
                      _displayMode,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Progress info
        Text(
          'Frame ${state.currentFrameIndex + 1} of ${state.frameResults.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                final cubit = context.read<PoseCubit>();
                cubit.togglePlayback();
              },
              icon: Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Slider(
                value: state.currentFrameIndex.toDouble(),
                min: 0,
                max: (state.frameResults.length - 1).toDouble(),
                onChanged: (value) {
                  // TODO: Implement frame seeking
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Text(
          'Average keypoints per frame: ${(state.frameResults.fold<int>(0, (sum, result) => sum + result.keypoints.length) / state.frameResults.length).round()}',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class _KeypointPainter extends CustomPainter {
  final List<Keypoint> keypoints;
  final int imageWidth;
  final int imageHeight;
  final KeypointDisplayMode displayMode;

  _KeypointPainter(
    this.keypoints,
    this.imageWidth,
    this.imageHeight,
    this.displayMode,
  );

  // MediaPipe pose keypoints indices
  static const Set<int> rightLegIndices = {24, 26, 28, 30, 32};
  static const Set<int> leftLegIndices = {23, 25, 27, 29, 31};

  List<Keypoint> _filterKeypoints() {
    switch (displayMode) {
      case KeypointDisplayMode.all:
        return keypoints;
      case KeypointDisplayMode.rightLeg:
        return keypoints
            .where((kp) => rightLegIndices.contains(keypoints.indexOf(kp)))
            .toList();
      case KeypointDisplayMode.leftLeg:
        return keypoints
            .where((kp) => leftLegIndices.contains(keypoints.indexOf(kp)))
            .toList();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final filteredKeypoints = _filterKeypoints();

    for (final kp in filteredKeypoints) {
      // Skip low confidence keypoints
      if (kp.score < 0.5) continue;

      final paint = Paint()
        ..color = _getKeypointColor(keypoints.indexOf(kp))
        ..style = PaintingStyle.fill;

      // Convert normalized coordinates to canvas coordinates
      final canvasX = kp.x * size.width;
      final canvasY = kp.y * size.height;

      canvas.drawCircle(Offset(canvasX, canvasY), 4, paint);
    }
  }

  Color _getKeypointColor(int index) {
    // Different colors for different body parts
    if (rightLegIndices.contains(index)) return Colors.blue;
    if (leftLegIndices.contains(index)) return Colors.green;
    return Colors.red;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
