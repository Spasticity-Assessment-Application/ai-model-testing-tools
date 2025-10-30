import AVFoundation
import CoreMedia
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "pose_native", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleMethodCall(call, result: result)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "runPoseEstimationOnImage":
      handlePoseEstimation(call, result: result)
    case "getVideoDuration":
      handleGetVideoDuration(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handlePoseEstimation(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let imagePath = args["imagePath"] as? String
    else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "imagePath is required", details: nil))
      return
    }

    let modelName = args["modelAssetName"] as? String ?? "pose_landmarker_lite"

    print("🍎 iOS: Using model: \(modelName)")

    let poseService = PoseService(modelAssetName: modelName)

    do {
      let keypoints = try poseService.estimatePose(imagePath: imagePath)
      result(["keypoints": keypoints])
    } catch let error as PoseEstimationError {
      result(
        FlutterError(
          code: "POSE_ESTIMATION_FAILED", message: error.localizedDescription, details: nil))
    } catch {
      result(FlutterError(code: "UNKNOWN_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  private func handleGetVideoDuration(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let videoPath = args["videoPath"] as? String
    else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "videoPath is required", details: nil))
      return
    }

    let url = URL(fileURLWithPath: videoPath)
    let asset = AVAsset(url: url)

    let duration = asset.duration
    let durationSeconds = CMTimeGetSeconds(duration)

    if durationSeconds.isNaN || durationSeconds.isInfinite {
      result(
        FlutterError(code: "VIDEO_DURATION_FAILED", message: "Invalid video duration", details: nil)
      )
      return
    }

    result(durationSeconds)
  }
}
