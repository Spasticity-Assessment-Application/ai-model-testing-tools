import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var poseService: PoseService?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    poseService = PoseService()

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

    guard let poseService = poseService else {
      result(
        FlutterError(
          code: "SERVICE_UNAVAILABLE", message: "Pose service not initialized", details: nil))
      return
    }

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
}
