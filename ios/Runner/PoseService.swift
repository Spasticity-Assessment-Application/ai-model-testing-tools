import Foundation
import MediaPipeTasksVision
import UIKit

class PoseService {
    private var landmarker: PoseLandmarker?

    private let modelAssetName = "pose_landmarker_lite"
    private let modelAssetType = "task"

    init() {
        initializeLandmarker()
    }

    private func initializeLandmarker() {
        do {
            guard
                let modelPath = Bundle.main.path(
                    forResource: modelAssetName, ofType: modelAssetType)
            else {
                throw PoseEstimationError.modelNotFound
            }

            let options = PoseLandmarkerOptions()
            options.baseOptions.modelAssetPath = modelPath
            options.runningMode = .image

            landmarker = try PoseLandmarker(options: options)
        } catch {
            print("Failed to initialize pose landmarker: \(error.localizedDescription)")
        }
    }

    func estimatePose(imagePath: String) throws -> [[String: Any]] {
        guard let landmarker = landmarker else {
            throw PoseEstimationError.landmarkerNotInitialized
        }

        guard let image = UIImage(contentsOfFile: imagePath) else {
            throw PoseEstimationError.imageNotFound
        }

        let mpImage = try MPImage(uiImage: image)
        let poseResult = try landmarker.detect(image: mpImage)

        return extractKeypoints(from: poseResult)
    }

    private func extractKeypoints(from poseResult: PoseLandmarkerResult) -> [[String: Any]] {
        var keypoints: [[String: Any]] = []

        for landmarkList in poseResult.landmarks {
            for landmark in landmarkList {
                let keypoint: [String: Any] = [
                    "x": landmark.x,
                    "y": landmark.y,
                    "z": landmark.z,
                    "score": landmark.visibility,
                ]
                keypoints.append(keypoint)
            }
        }

        return keypoints
    }

    func close() {
        landmarker = nil
    }

    deinit {
        close()
    }
}

enum PoseEstimationError: LocalizedError {
    case modelNotFound
    case landmarkerNotInitialized
    case imageNotFound
    case detectionFailed(Error)

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Pose estimation model not found in bundle"
        case .landmarkerNotInitialized:
            return "Pose landmarker is not initialized"
        case .imageNotFound:
            return "Failed to load image from path"
        case .detectionFailed(let error):
            return "Pose detection failed: \(error.localizedDescription)"
        }
    }
}
