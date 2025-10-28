package com.example.poc

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pose_native"
    private lateinit var poseService: PoseService

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        poseService = PoseService(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "runPoseEstimationOnImage" -> handlePoseEstimation(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handlePoseEstimation(call: io.flutter.plugin.common.MethodCall, result: io.flutter.plugin.common.MethodChannel.Result) {
        val imagePath = call.argument<String>("imagePath")
        if (imagePath.isNullOrEmpty()) {
            result.error("INVALID_ARGUMENT", "imagePath is required", null)
            return
        }

        try {
            val keypoints = poseService.estimatePose(imagePath)
            result.success(mapOf("keypoints" to keypoints))
        } catch (e: Exception) {
            result.error("POSE_ESTIMATION_FAILED", e.localizedMessage ?: "Unknown error", null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        poseService.close()
    }
}
