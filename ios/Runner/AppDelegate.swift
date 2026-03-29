import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let aiSecretChannelName = AiSecretStoreChannel.channelName
  private var aiSecretChannel: FlutterMethodChannel?
  private let aiSecretStoreChannel = AiSecretStoreChannel()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let aiSecretChannel = FlutterMethodChannel(
        name: aiSecretChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      self.aiSecretChannel = aiSecretChannel
      aiSecretChannel.setMethodCallHandler { [weak self] call, result in
        self?.aiSecretStoreChannel.handle(call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
