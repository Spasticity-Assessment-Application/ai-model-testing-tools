import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../logic/pose_cubit.dart';
import '../logic/pose_state.dart';
import '../data/pose_repository.dart';

class PosePage extends StatefulWidget {
  const PosePage({super.key});

  @override
  State<PosePage> createState() => _PosePageState();
}

enum KeypointDisplayMode { all, rightLeg, leftLeg }

class _PosePageState extends State<PosePage> {
  String? _videoPath;
  Uint8List? _thumbnailBytes;
  KeypointDisplayMode _displayMode = KeypointDisplayMode.all;

  late PoseCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PoseCubit();
    _cubit.initialize();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.video);
    if (res == null || res.files.isEmpty) return;
    final path = res.files.first.path;
    if (path == null) return;

    setState(() {
      _videoPath = path;
      _thumbnailBytes = null;
    });
  }

  void _analyze() async {
    if (_videoPath == null) return;
    await _cubit.analyzeVideoFrames(
      _videoPath!,
      frameCount: 30,
      durationMs: 5000,
    );
  }

  Widget _buildDisplayModeButton(String label, KeypointDisplayMode mode) {
    final isSelected = _displayMode == mode;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _displayMode = mode;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildThumbnail() {
    if (_videoPath == null) return const SizedBox.shrink();
    // Let repository or video_thumbnail provide the thumbnail through cubit result
    if (_thumbnailBytes != null) {
      return Stack(
        children: [
          Image.memory(_thumbnailBytes!),
          Positioned.fill(
            child: BlocBuilder<PoseCubit, PoseState>(
              bloc: _cubit,
              builder: (context, state) {
                if (state is PoseResultState) {
                  return CustomPaint(
                    painter: _KeypointPainter(
                      state.result.keypoints,
                      state.imageWidth,
                      state.imageHeight,
                      _displayMode,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      );
    }

    // When video is selected but not analyzed yet, show placeholder
    return Container(
      width: 256,
      height: 256,
      color: Colors.grey[200],
      child: const Center(child: Text('Video ready for analysis')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pose test')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.video_library),
              label: const Text('Pick video'),
            ),
            const SizedBox(height: 12),

            if (_videoPath != null) ...[
              Text(
                'Video selected: ${_videoPath!.split(Platform.pathSeparator).last}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _analyze,
                child: const Text('Analyze video frames'),
              ),
              const SizedBox(height: 16),
            ],

            Expanded(
              child: BlocConsumer<PoseCubit, PoseState>(
                bloc: _cubit,
                listener: (context, state) {
                  if (state is PoseResultState) {
                    VideoThumbnail.thumbnailData(
                      video: state.sourcePath,
                      imageFormat: ImageFormat.PNG,
                      timeMs: 0,
                      quality: 75,
                      maxWidth: 256,
                      maxHeight: 256,
                    ).then((bytes) {
                      setState(() {
                        _thumbnailBytes = bytes;
                      });
                    });
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
            Text('Analyzing video...'),
          ],
        ),
      );
    }

    if (state is PoseError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: ${state.message}'),
          ],
        ),
      );
    }

    if (state is PoseVideoAnalysisState) {
      return _buildVideoAnalysisContent(state);
    }

    if (state is PoseResultState) {
      return _buildResultContent(state);
    }

    return _buildThumbnail();
  }

  Widget _buildVideoAnalysisContent(PoseVideoAnalysisState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Video Playback',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 280,
                      height: 280,
                      color: Colors.black,
                      child: state.frameImages.isNotEmpty
                          ? Image.memory(
                              state.frameImages[state.currentFrameIndex.clamp(
                                0,
                                state.frameImages.length - 1,
                              )],
                              fit: BoxFit.contain,
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'Pose Keypoints',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 280,
                      height: 280,
                      color: Colors.black,
                      child: CustomPaint(
                        painter: _KeypointPainter(
                          state.frameResults.isNotEmpty
                              ? state
                                    .frameResults[state.currentFrameIndex.clamp(
                                      0,
                                      state.frameResults.length - 1,
                                    )]
                                    .keypoints
                              : [],
                          state.frameWidths.isNotEmpty
                              ? state.frameWidths[state.currentFrameIndex.clamp(
                                  0,
                                  state.frameWidths.length - 1,
                                )]
                              : 256,
                          state.frameHeights.isNotEmpty
                              ? state.frameHeights[state.currentFrameIndex
                                    .clamp(0, state.frameHeights.length - 1)]
                              : 256,
                          _displayMode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                IconButton(
                  onPressed: _cubit.togglePlayback,
                  icon: Icon(
                    state.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 32,
                  ),
                  tooltip: state.isPlaying ? 'Pause' : 'Play',
                ),
                Text(
                  'Frame ${state.currentFrameIndex + 1}/${state.frameResults.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDisplayModeButton('Tout', KeypointDisplayMode.all),
                  const SizedBox(width: 8),
                  _buildDisplayModeButton(
                    'Jambe D',
                    KeypointDisplayMode.rightLeg,
                  ),
                  const SizedBox(width: 8),
                  _buildDisplayModeButton(
                    'Jambe G',
                    KeypointDisplayMode.leftLeg,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text('Current keypoints (x,y,score):'),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              itemCount: state.frameResults.isNotEmpty
                  ? state
                        .frameResults[state.currentFrameIndex.clamp(
                          0,
                          state.frameResults.length - 1,
                        )]
                        .keypoints
                        .length
                  : 0,
              itemBuilder: (context, index) {
                final frameIndex = state.currentFrameIndex.clamp(
                  0,
                  state.frameResults.length - 1,
                );
                final k = state.frameResults[frameIndex].keypoints[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    'kp $index: (${k.x.toStringAsFixed(2)}, ${k.y.toStringAsFixed(2)})',
                  ),
                  trailing: Text(k.score.toStringAsFixed(2)),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildResultContent(PoseResultState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_thumbnailBytes != null)
            Center(
              child: SizedBox(
                width: 256,
                height: 256,
                child: Stack(
                  children: [
                    Image.memory(_thumbnailBytes!),
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

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDisplayModeButton('Tout', KeypointDisplayMode.all),
                  const SizedBox(width: 8),
                  _buildDisplayModeButton(
                    'Jambe D',
                    KeypointDisplayMode.rightLeg,
                  ),
                  const SizedBox(width: 8),
                  _buildDisplayModeButton(
                    'Jambe G',
                    KeypointDisplayMode.leftLeg,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text('Top keypoints (x,y,score):'),
          const SizedBox(height: 8),
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              itemCount: state.result.keypoints.length,
              itemBuilder: (context, index) {
                final k = state.result.keypoints[index];
                return ListTile(
                  title: Text(
                    'kp $index: (${k.x.toStringAsFixed(2)}, ${k.y.toStringAsFixed(2)})',
                  ),
                  trailing: Text(k.score.toStringAsFixed(2)),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
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
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Calculate scale factors to fit image into the widget size while maintaining aspect ratio
    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Calculate offsets to center the image
    final scaledWidth = imageWidth * scale;
    final scaledHeight = imageHeight * scale;
    final offsetX = (size.width - scaledWidth) / 2;
    final offsetY = (size.height - scaledHeight) / 2;

    final filteredKeypoints = _filterKeypoints();
    for (final kp in filteredKeypoints) {
      // Keypoints are normalized (0-1), so multiply by actual image dimensions
      final dx = (kp.x * imageWidth * scale) + offsetX;
      final dy = (kp.y * imageHeight * scale) + offsetY;
      canvas.drawCircle(Offset(dx, dy), 4.0, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
