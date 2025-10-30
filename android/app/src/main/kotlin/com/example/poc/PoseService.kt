package com.example.poc

import android.content.Context
import android.graphics.BitmapFactory
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.framework.image.BitmapImageBuilder
import java.nio.ByteBuffer

class PoseService(private val context: Context, private val modelAssetName: String = "pose_landmarker_lite") {
    private var landmarker: PoseLandmarker? = null

    init {
        println("🤖 Android PoseService: Initializing with model: $modelAssetName")
        initializeLandmarker()
    }

    private fun initializeLandmarker() {
        try {
            val assetManager = context.assets
            val modelBuffer = assetManager.open("$modelAssetName.task").readBytes()
            val byteBuffer = ByteBuffer.wrap(modelBuffer)
            val options = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(
                    BaseOptions.builder()
                        .setModelAssetBuffer(byteBuffer)
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

            val mpImage = BitmapImageBuilder(bitmap).build()
            val poseResult: PoseLandmarkerResult = landmarker.detect(mpImage)

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