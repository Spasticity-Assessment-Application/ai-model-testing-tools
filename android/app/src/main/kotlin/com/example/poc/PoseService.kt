package com.example.poc

import android.content.Context
import android.graphics.BitmapFactory
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.core.VisionImage

class PoseService(private val context: Context) {
    private var landmarker: PoseLandmarker? = null

    companion object {
        private const val MODEL_ASSET = "pose_landmarker_lite.task"
    }

    init {
        initializeLandmarker()
    }

    private fun initializeLandmarker() {
        try {
            val assetManager = context.assets
            val modelBuffer = assetManager.open(MODEL_ASSET).readBytes()
            val options = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(
                    PoseLandmarker.BaseOptions.builder()
                        .setModelAssetBuffer(modelBuffer)
                        .build()
                )
                .setRunningMode(RunningMode.IMAGE)
                .build()

            landmarker = PoseLandmarker.createFromOptions(context, options)
        } catch (e: Exception) {
            throw PoseEstimationException("Failed to initialize pose landmarker: ${e.localizedMessage}", e)
        }
    }

    fun estimatePose(imagePath: String): List<Map<String, Any>> {
        val landmarker = this.landmarker ?: throw PoseEstimationException("Landmarker not initialized")

        return try {
            val bitmap = BitmapFactory.decodeFile(imagePath)
                ?: throw PoseEstimationException("Failed to decode image: $imagePath")

            val visionImage = VisionImage.fromBitmap(bitmap)
            val poseResult: PoseLandmarkerResult = landmarker.detect(visionImage)

            extractKeypoints(poseResult)
        } catch (e: Exception) {
            throw PoseEstimationException("Pose estimation failed: ${e.localizedMessage}", e)
        }
    }

    private fun extractKeypoints(poseResult: PoseLandmarkerResult): List<Map<String, Any>> {
        return poseResult.landmarks().flatMap { landmarkList ->
            landmarkList.map { landmark ->
                mapOf(
                    "x" to landmark.x(),
                    "y" to landmark.y(),
                    "z" to landmark.z(),
                    "score" to landmark.visibility()
                )
            }
        }
    }

    fun close() {
        landmarker?.close()
        landmarker = null
    }
}

class PoseEstimationException(message: String, cause: Throwable? = null) : Exception(message, cause)