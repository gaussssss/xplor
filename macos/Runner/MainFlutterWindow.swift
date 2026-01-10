import Cocoa
import FlutterMacOS

// Simple native tag bridge for macOS Finder tags
@available(macOS 13.0, *)
fileprivate class TagChannel {
  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "xplor/tags",
      binaryMessenger: controller.engine.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getTag":
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
          result(FlutterError(code: "bad_args", message: "Missing path", details: nil))
          return
        }
        result(fetchTag(path: path))

      case "setTag":
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let tag = args["tag"] as? String else {
          result(FlutterError(code: "bad_args", message: "Missing path/tag", details: nil))
          return
        }
        do {
          try applyTag(path: path, tag: tag)
          result(true)
        } catch {
          result(FlutterError(code: "tag_error", message: error.localizedDescription, details: nil))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func fetchTag(path: String) -> String? {
    guard #available(macOS 26.0, *) else { return nil }
    let url = URL(fileURLWithPath: path)
    do {
      let values = try url.resourceValues(forKeys: [.tagNamesKey])
      return values.tagNames?.first
    } catch {
      return nil
    }
  }

  private static func applyTag(path: String, tag: String) throws {
    guard #available(macOS 26.0, *) else { return }
    var url = URL(fileURLWithPath: path)
    let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
    var values = try url.resourceValues(forKeys: [.tagNamesKey])
    values.tagNames = trimmed.isEmpty ? [] : [trimmed]
    try url.setResourceValues(values)
  }
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    if #available(macOS 13.0, *) {
      TagChannel.register(with: flutterViewController)
    }

    super.awakeFromNib()
  }
}
