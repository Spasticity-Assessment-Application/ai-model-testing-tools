package com.example.poc

import android.media.MediaMetadataRetriever
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pose_native"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "runPoseEstimationOnImage" -> handlePoseEstimation(call, result)
                "getVideoDuration" -> handleGetVideoDuration(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handlePoseEstimation(call: io.flutter.plugin.common.MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        val imagePath = call.argument<String>("imagePath")
        val modelName = call.argument<String>("modelAssetName") ?: "pose_landmarker_lite"

        println("📱 Android: Using model: $modelName")

        if (imagePath.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENT", "imagePath is required", null)
            return
        }

        try {
            // Create service with the specified model
            val service = PoseService(applicationContext, modelName)
            val keypoints = service.estimatePose(imagePath)
            result.success(mapOf("keypoints" to keypoints))
            service.close()
        } catch (e: Exception) {
            result.error("POSE_ESTIMATION_FAILED", e.localizedMessage ?: "Unknown error", null)
        }
    }

    private fun handleGetVideoDuration(call: io.flutter.plugin.common.MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        val videoPath = call.argument<String>("videoPath")

        if (videoPath.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENT", "videoPath is required", null)
            return
        }

        try {
            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(videoPath)
            val durationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            retriever.release()

            if (durationStr != null) {
                val durationMs = durationStr.toLong()
                val durationSeconds = durationMs / 1000.0
                result.success(durationSeconds)
            } else {
                result.error("DURATION_EXTRACTION_FAILED", "Could not extract video duration", null)
            }
        } catch (e: Exception) {
            result.error("VIDEO_PROCESSING_FAILED", e.localizedMessage ?: "Unknown error", null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
    }
}
