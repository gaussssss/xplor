import Foundation
import FlutterMacOS

class TagChannel {
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
    let url = URL(fileURLWithPath: path)
    do {
      let values = try url.resourceValues(forKeys: [.tagNamesKey])
      return values.tagNames?.first
    } catch {
      return nil
    }
  }

  private static func applyTag(path: String, tag: String) throws {
    let url = URL(fileURLWithPath: path)
    var values = URLResourceValues()
    let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      values.tagNames = []
    } else {
      values.tagNames = [trimmed]
    }
    try url.setResourceValues(values)
  }
}
