import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail/video_thumbnail.dart';
import '../data/pose_repository.dart';
import 'pose_state.dart';

class PoseCubit extends Cubit<PoseState> {
  final PoseRepository _repository;
  Timer? _playbackTimer;

  PoseCubit({PoseRepository? repository})
    : _repository = repository ?? PoseRepository(),
      super(PoseInitial());

  Future<void> initialize() async {
    try {
      emit(PoseLoading());
      await _repository.initialize();
      emit(PoseReady());
    } catch (e) {
      emit(PoseError('Initialization failed: $e'));
    }
  }

  Future<void> analyzeVideo(String videoPath, {int timeMs = 0}) async {
    if (!_repository.isInitialized) {
      emit(PoseError('Repository not initialized'));
      return;
    }

    try {
      emit(PoseLoading());

      final thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.PNG,
        timeMs: timeMs,
        quality: 75,
        maxWidth: 256,
        maxHeight: 256,
      );

      if (thumbnailBytes == null) {
        emit(PoseError('Failed to extract thumbnail'));
        return;
      }

      final image = img.decodeImage(thumbnailBytes);
      if (image == null) {
        emit(PoseError('Failed to decode thumbnail'));
        return;
      }

      final res = await _repository.analyzeVideoFrame(
        videoPath,
        timeMs: timeMs,
      );
      emit(
        PoseResultState(
          result: res,
          sourcePath: videoPath,
          imageWidth: image.width,
          imageHeight: image.height,
        ),
      );
    } catch (e) {
      emit(PoseError('Analysis failed: $e'));
    }
  }

  Future<void> analyzeVideoFrames(
    String videoPath, {
    int frameCount = 20,
    int durationMs = 3000,
  }) async {
    if (!_repository.isInitialized) {
      emit(PoseError('Repository not initialized'));
      return;
    }

    try {
      emit(PoseLoading());

      final List<PoseResult> frameResults = [];
      final List<Uint8List> frameImages = [];
      final List<int> frameWidths = [];
      final List<int> frameHeights = [];

      final intervalMs = durationMs ~/ frameCount;

      for (int i = 0; i < frameCount; i++) {
        final timeMs = i * intervalMs;

        final frameBytes = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.PNG,
          timeMs: timeMs,
          quality: 75,
          maxWidth: 256,
          maxHeight: 256,
        );

        if (frameBytes != null) {
          frameImages.add(frameBytes);

          final image = img.decodeImage(frameBytes);
          if (image != null) {
            frameWidths.add(image.width);
            frameHeights.add(image.height);

            final result = await _repository.analyzeVideoFrame(
              videoPath,
              timeMs: timeMs,
            );
            frameResults.add(result);
          } else {
            continue;
          }
        } else {
          continue;
        }
      }

      if (frameResults.isNotEmpty && frameImages.isNotEmpty) {
        emit(
          PoseVideoAnalysisState(
            frameResults: frameResults,
            frameImages: frameImages,
            frameWidths: frameWidths,
            frameHeights: frameHeights,
            sourcePath: videoPath,
            currentFrameIndex: 0,
            isPlaying: true,
          ),
        );

        // Start playback
        _startPlayback(frameResults.length);
      } else {
        emit(PoseError('Failed to extract any valid frames from video'));
      }
    } catch (e) {
      emit(PoseError('Video analysis failed: $e'));
    }
  }

  void _startPlayback(int frameCount) {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 167), (timer) {
      if (state is PoseVideoAnalysisState) {
        final currentState = state as PoseVideoAnalysisState;
        final nextIndex =
            (currentState.currentFrameIndex + 1) %
            currentState.frameResults.length;

        emit(
          PoseVideoAnalysisState(
            frameResults: currentState.frameResults,
            frameImages: currentState.frameImages,
            frameWidths: currentState.frameWidths,
            frameHeights: currentState.frameHeights,
            sourcePath: currentState.sourcePath,
            currentFrameIndex: nextIndex,
            isPlaying: true,
          ),
        );
      }
    });
  }

  void togglePlayback() {
    if (state is PoseVideoAnalysisState) {
      final currentState = state as PoseVideoAnalysisState;
      if (currentState.isPlaying) {
        _playbackTimer?.cancel();
        emit(
          PoseVideoAnalysisState(
            frameResults: currentState.frameResults,
            frameImages: currentState.frameImages,
            frameWidths: currentState.frameWidths,
            frameHeights: currentState.frameHeights,
            sourcePath: currentState.sourcePath,
            currentFrameIndex: currentState.currentFrameIndex,
            isPlaying: false,
          ),
        );
      } else {
        _startPlayback(currentState.frameResults.length);
      }
    }
  }

  @override
  Future<void> close() async {
    _playbackTimer?.cancel();
    _repository.dispose();
    return super.close();
  }
}
