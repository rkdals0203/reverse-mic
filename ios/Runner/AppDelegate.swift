import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var sharedUrl: String?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let shareChannel = FlutterMethodChannel(name: "com.example.reverse_mic/share",
                                              binaryMessenger: controller.binaryMessenger)
    
    shareChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "getSharedUrl":
        result(self.sharedUrl)
        self.sharedUrl = nil // 한 번 사용 후 초기화
      default:
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    sharedUrl = url.absoluteString
    return true
  }
}
