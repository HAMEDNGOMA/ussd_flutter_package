import 'package:flutter/services.dart';
import 'ussd_service.dart';

class UssdFlutterPackage {
  static const MethodChannel _methodChannel =
      MethodChannel('ussd_flutter_package');
  static const EventChannel _eventChannel =
      EventChannel('ussd_flutter_package/events');

  static Future<String?> getPlatformVersion() {
    return _methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  static Future<UssdResponse> sendUssd(String ussdCode) async {
    final result =
        await _methodChannel.invokeMethod('sendUssd', {'ussdCode': ussdCode});

    final map = Map<String, dynamic>.from(result); // ✅ cast safely
    return UssdResponse.fromMap(map);
  }

  static Future<UssdResponse> sendResponse(String response) async {
    final result = await _methodChannel
        .invokeMethod('sendResponse', {'response': response});
    final map = Map<String, dynamic>.from(result);
    return UssdResponse.fromMap(map);
  }

  static Stream<UssdResponse> get ussdResponseStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final map = Map<dynamic, dynamic>.from(event);
      return UssdResponse.fromMap(
          map.map((key, value) => MapEntry(key.toString(), value)));
    });
  }

  static Future<bool> isUssdSupported() async {
    final result = await _methodChannel.invokeMethod('isUssdSupported');
    return result == true;
  }
}
