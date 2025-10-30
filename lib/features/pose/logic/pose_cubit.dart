import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:video_thumbnail/video_thumbnail.dart';
import '../data/pose_repository.dart';
import '../data/pose_model.dart';
import '../data/media_pipe_pose_model.dart';
import 'pose_state.dart';

class PoseCubit extends Cubit<PoseState> {
  final PoseRepository _repository;
  Timer? _playbackTimer;
  bool _isPlaybackActive = false;

  static const MethodChannel _videoChannel = MethodChannel('pose_native');

  PoseCubit({PoseModel? poseModel})
    : _repository = PoseRepository(poseModel ?? MediaPipePoseModel()),
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

  // Get video duration (native method returns seconds).
  Future<Duration> _getVideoDuration(String videoPath) async {
    try {
      final double durationSeconds = await _videoChannel.invokeMethod(
        'getVideoDuration',
        {'videoPath': videoPath},
      );
      final int durationMs = (durationSeconds * 1000).round();
      return Duration(milliseconds: durationMs);
    } catch (_) {
      return const Duration(seconds: 30);
    }
  }

  Future<void> analyzeVideoFrames(
    String videoPath, {
    int? frameCount,
    int? durationMs,
    bool analyzeFullVideo = false,
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

      // Prepare sampling parameters
      int actualFrameCount = frameCount ?? 20;
      int actualDurationMs = durationMs ?? 3000;

      if (analyzeFullVideo) {
        final videoDuration = await _getVideoDuration(videoPath);
        actualDurationMs = videoDuration.inMilliseconds;
        if (frameCount == null) {
          final targetFrameRate = 2.0; // frames per second
          actualFrameCount = (actualDurationMs / 1000 * targetFrameRate)
              .round()
              .clamp(20, 100);
        }
      }

      final intervalMs = actualDurationMs ~/ actualFrameCount;
      const int maxRetries = 3;

      for (int i = 0; i < actualFrameCount; i++) {
        final int timeMs = i * intervalMs;
        bool frameExtracted = false;
        for (int retry = 0; retry < maxRetries && !frameExtracted; retry++) {
          final adjustedTimeMs = timeMs + (retry * 100);
          try {
            final frameBytes = await VideoThumbnail.thumbnailData(
              video: videoPath,
              imageFormat: ImageFormat.PNG,
              timeMs: adjustedTimeMs,
              quality: 75,
              maxWidth: 256,
              maxHeight: 256,
            );
            if (frameBytes == null) continue;
            final image = img.decodeImage(frameBytes);
            if (image == null) continue;
            frameImages.add(frameBytes);
            frameWidths.add(image.width);
            frameHeights.add(image.height);
            final result = await _repository.analyzeVideoFrame(
              videoPath,
              timeMs: adjustedTimeMs,
            );
            frameResults.add(result);
            frameExtracted = true;
          } catch (_) {
            // ignore and retry
          }
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
    _isPlaybackActive = true;
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 167), (timer) {
      if (!_isPlaybackActive) {
        timer.cancel();
        return;
      }
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
        _isPlaybackActive = false;
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
    _isPlaybackActive = false;
    _playbackTimer?.cancel();
    _repository.dispose();
    return super.close();
  }
}
