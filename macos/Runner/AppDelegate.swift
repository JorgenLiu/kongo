import Cocoa
import FlutterMacOS
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  private let reminderChannelName = "kongo/reminders"
  private let aiSecretChannelName = AiSecretStoreChannel.channelName
  private let reminderPrefix = "kongo."
  private let eventCategoryId = "kongo.reminder.event"
  private let eventFollowUpCategoryId = "kongo.reminder.eventFollowUp"
  private let notificationCenter = UNUserNotificationCenter.current()
  private var reminderChannel: FlutterMethodChannel?
  private var aiSecretChannel: FlutterMethodChannel?
  private let aiSecretStoreChannel = AiSecretStoreChannel()
  private var pendingReminderInteraction: [String: String]?

  /// Called from MainFlutterWindow.awakeFromNib() after the FlutterViewController
  /// is created, avoiding the applicationDidFinishLaunching override that causes
  /// an unrecognized-selector crash with FlutterAppDelegate on macOS.
  func configureFlutterChannels(controller: FlutterViewController) {
    notificationCenter.delegate = self
    registerReminderCategories()

    let reminderChannel = FlutterMethodChannel(
      name: reminderChannelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    self.reminderChannel = reminderChannel

    reminderChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleReminderCall(call, result: result)
    }

    let aiSecretChannel = FlutterMethodChannel(
      name: aiSecretChannelName,
      binaryMessenger: controller.engine.binaryMessenger
    )
    self.aiSecretChannel = aiSecretChannel
    aiSecretChannel.setMethodCallHandler { [weak self] call, result in
      self?.aiSecretStoreChannel.handle(call, result: result)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func handleReminderCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAuthorizationStatus":
      notificationCenter.getNotificationSettings { settings in
        result(self.mapAuthorizationStatus(settings.authorizationStatus))
      }
    case "requestAuthorization":
      notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
        if let error {
          result(
            FlutterError(
              code: "request_authorization_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
          return
        }

        self.notificationCenter.getNotificationSettings { settings in
          result(self.mapAuthorizationStatus(settings.authorizationStatus))
        }
      }
    case "schedule":
      guard
        let arguments = call.arguments as? [String: Any],
        let identifier = arguments["id"] as? String,
        let title = arguments["title"] as? String,
        let body = arguments["body"] as? String,
        let fireAtMillis = arguments["fireAt"] as? Int64
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Missing reminder payload",
            details: nil
          )
        )
        return
      }

      let fireDate = Date(timeIntervalSince1970: TimeInterval(fireAtMillis) / 1000)
      let timeInterval = fireDate.timeIntervalSinceNow
      if timeInterval <= 0 {
        result(nil)
        return
      }

      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default
      if let payload = arguments["payload"] as? [String: String] {
        content.userInfo = payload
        if let categoryIdentifier = categoryIdentifier(for: payload["targetType"]) {
          content.categoryIdentifier = categoryIdentifier
        }
      }

      let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: max(timeInterval, 1),
        repeats: false
      )
      let request = UNNotificationRequest(
        identifier: identifier,
        content: content,
        trigger: trigger
      )

      notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
      notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
      notificationCenter.add(request) { error in
        if let error {
          result(
            FlutterError(
              code: "schedule_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
          return
        }

        result(nil)
      }
    case "cancel":
      guard
        let arguments = call.arguments as? [String: Any],
        let identifier = arguments["id"] as? String
      else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Missing reminder id",
            details: nil
          )
        )
        return
      }

      notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
      notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
      result(nil)
    case "cancelAll":
      notificationCenter.getPendingNotificationRequests { requests in
        let pendingIds = requests
          .map(\ .identifier)
          .filter { $0.hasPrefix(self.reminderPrefix) }
        if !pendingIds.isEmpty {
          self.notificationCenter.removePendingNotificationRequests(withIdentifiers: pendingIds)
        }

        self.notificationCenter.getDeliveredNotifications { notifications in
          let deliveredIds = notifications
            .map { $0.request.identifier }
            .filter { $0.hasPrefix(self.reminderPrefix) }
          if !deliveredIds.isEmpty {
            self.notificationCenter.removeDeliveredNotifications(withIdentifiers: deliveredIds)
          }

          result(nil)
        }
      }
    case "consumePendingInteraction":
      let payload = pendingReminderInteraction
      pendingReminderInteraction = nil
      result(payload)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let identifier = response.notification.request.identifier
    guard identifier.hasPrefix(reminderPrefix) else {
      completionHandler()
      return
    }

    if response.actionIdentifier == UNNotificationDismissActionIdentifier {
      completionHandler()
      return
    }

    var payload: [String: String] = [:]
    for (key, value) in response.notification.request.content.userInfo {
      guard let stringKey = key as? String, let stringValue = value as? String else {
        continue
      }
      payload[stringKey] = stringValue
    }
    if response.actionIdentifier != UNNotificationDefaultActionIdentifier {
      payload["actionId"] = response.actionIdentifier
    }
    if !payload.isEmpty {
      pendingReminderInteraction = payload
      reminderChannel?.invokeMethod("onReminderInteraction", arguments: payload)
    }

    completionHandler()
  }

  private func mapAuthorizationStatus(_ status: UNAuthorizationStatus) -> String {
    switch status {
    case .authorized, .provisional, .ephemeral:
      return "authorized"
    case .denied:
      return "denied"
    case .notDetermined:
      return "notDetermined"
    @unknown default:
      return "unsupported"
    }
  }

  private func registerReminderCategories() {
    let tenMinutesAction = UNNotificationAction(
      identifier: "ten_minutes",
      title: "10 分钟后提醒",
      options: []
    )
    let laterTodayAction = UNNotificationAction(
      identifier: "later_today",
      title: "今天晚些时候提醒",
      options: []
    )

    let eventCategory = UNNotificationCategory(
      identifier: eventCategoryId,
      actions: [tenMinutesAction, laterTodayAction],
      intentIdentifiers: [],
      options: []
    )
    let followUpCategory = UNNotificationCategory(
      identifier: eventFollowUpCategoryId,
      actions: [tenMinutesAction, laterTodayAction],
      intentIdentifiers: [],
      options: []
    )

    notificationCenter.setNotificationCategories([eventCategory, followUpCategory])
  }

  private func categoryIdentifier(for targetType: String?) -> String? {
    switch targetType {
    case "event":
      return eventCategoryId
    case "eventFollowUp":
      return eventFollowUpCategoryId
    default:
      return nil
    }
  }
}
