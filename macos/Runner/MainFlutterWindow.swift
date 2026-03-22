import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    var windowFrame = self.frame
    windowFrame.size = NSSize(width: 1360, height: 900)
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.center()
    self.contentMinSize = NSSize(width: 1000, height: 680)

    self.title = "Kongo"
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.isMovableByWindowBackground = true
    self.backgroundColor = NSColor.windowBackgroundColor
    self.styleMask.insert(.fullSizeContentView)
    self.toolbar = nil

    if #available(macOS 11.0, *) {
      self.toolbarStyle = .unifiedCompact
      self.titlebarSeparatorStyle = .none
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
    let windowChannel = FlutterMethodChannel(
      name: "kongo/window_chrome",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    windowChannel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "updateWindowChrome" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let arguments = call.arguments as? [String: Any] else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Expected window chrome arguments",
            details: nil
          )
        )
        return
      }

      self?.applyWindowChrome(arguments)
      result(nil)
    }

    super.awakeFromNib()
  }

  private func applyWindowChrome(_ arguments: [String: Any]) {
    if let title = arguments["title"] as? String, !title.isEmpty {
      self.title = title
    }

    if let backgroundColorValue = arguments["backgroundColor"] as? NSNumber {
      let backgroundColor = color(fromARGB: backgroundColorValue.uint32Value)
      self.backgroundColor = backgroundColor
      self.contentView?.wantsLayer = true
      self.contentView?.layer?.backgroundColor = backgroundColor.cgColor
    }

    if let dark = arguments["dark"] as? Bool {
      self.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    }
  }

  private func color(fromARGB value: UInt32) -> NSColor {
    let alpha = CGFloat((value >> 24) & 0xFF) / 255.0
    let red = CGFloat((value >> 16) & 0xFF) / 255.0
    let green = CGFloat((value >> 8) & 0xFF) / 255.0
    let blue = CGFloat(value & 0xFF) / 255.0
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
  }
}
