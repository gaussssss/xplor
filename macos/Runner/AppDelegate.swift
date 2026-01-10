import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return false
    }
    let channel = FlutterMethodChannel(
      name: "xplor/navigation",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.invokeMethod("openFile", arguments: filename)
    return true
  }
}
