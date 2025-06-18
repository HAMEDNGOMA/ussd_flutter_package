import Flutter
import UIKit

public class UssdFlutterPackagePlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel
  private var eventChannel: FlutterEventChannel
  private var eventSink: FlutterEventSink? = nil

  public init(channel: FlutterMethodChannel, eventChannel: FlutterEventChannel) {
    self.channel = channel
    self.eventChannel = eventChannel
    super.init()
    self.channel.setMethodCallHandler(self.handle)
    self.eventChannel.setStreamHandler(self)
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "ussd_flutter_package", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "ussd_flutter_package/events", binaryMessenger: registrar.messenger())
    let instance = UssdFlutterPackagePlugin(channel: channel, eventChannel: eventChannel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "sendUssd":
      guard let ussdCode = call.arguments as? [String: Any], let code = ussdCode["ussdCode"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "ussdCode cannot be null", details: nil))
        return
      }
      sendUssdRequest(ussdCode: code, result: result)
    case "sendResponse":
      result(FlutterError(code: "NOT_SUPPORTED", message: "Sending USSD response is not supported on iOS.", details: nil))
    case "isUssdSupported":
      isUssdSupported(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func sendUssdRequest(ussdCode: String, result: @escaping FlutterResult) {
    // On iOS, direct USSD interaction is not possible for third-party apps.
    // We can only open the Phone app with the USSD code.
    // The app will not receive any response from the USSD session.
    if let url = URL(string: "tel://" + ussdCode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!),
       UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
      result(nil) // Indicate that the request was sent, but no response will be received.
    } else {
      result(FlutterError(code: "UNSUPPORTED_OPERATION", message: "Could not open dialer with USSD code.", details: nil))
    }
  }

  private func isUssdSupported(result: @escaping FlutterResult) {
    // On iOS, we can only check if the device can make phone calls.
    // This doesn't guarantee USSD support, but it's the closest we can get.
    if let url = URL(string: "tel://"), UIApplication.shared.canOpenURL(url) {
      result(true)
    } else {
      result(false)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}


