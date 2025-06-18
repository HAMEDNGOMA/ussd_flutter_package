import 'package:permission_handler/permission_handler.dart';
import 'package:ussd_flutter/ussd_flutter_package.dart';

enum UssdSessionState {
  started,
  continued,
  ended,
  error,
}

class UssdResponse {
  final String message;
  final UssdSessionState state;

  UssdResponse({required this.message, required this.state});

  // ✅ Add this static method
  factory UssdResponse.fromMap(Map<String, dynamic> map) {
    return UssdResponse(
      message: map['message'] ?? '',
      state: _parseState(map['state']?.toString()),
    );
  }

  // ✅ Method to convert text to enum
  static UssdSessionState _parseState(String? value) {
    switch (value) {
      case 'started':
        return UssdSessionState.started;
      case 'continued':
        return UssdSessionState.continued;
      case 'ended':
        return UssdSessionState.ended;
      case 'error':
        return UssdSessionState.error;
      default:
        return UssdSessionState.error;
    }
  }
}

class UssdService {
  // Singleton instance
  static final UssdService _instance = UssdService._internal();
  factory UssdService() {
    return _instance;
  }
  UssdService._internal();

  // Request phone permissions
  Future<bool> _requestPermissions() async {
    final statusPhone = await Permission.phone.status;
    if (!statusPhone.isGranted) {
      final result = await Permission.phone.request();
      return result.isGranted;
    }
    return true;
  }

  // Method to send USSD code (with permission check)
  Future<UssdResponse> sendUssd(String ussdCode) async {
    final permissionGranted = await _requestPermissions();
    if (!permissionGranted) {
      throw Exception(
          'Phone permission not granted. Please allow the permission in settings.');
    }

    return UssdFlutterPackage.sendUssd(ussdCode);
  }

  // Method to send a response to an active USSD session (Android only)
  Future<UssdResponse> sendResponse(String response) async {
    return UssdFlutterPackage.sendResponse(response);
  }

  // Stream to listen for USSD responses (Android only)
  Stream<UssdResponse> get ussdResponseStream {
    return UssdFlutterPackage.ussdResponseStream;
  }

  // Check if USSD is supported on the current platform
  Future<bool> isUssdSupported() async {
    return UssdFlutterPackage.isUssdSupported();
  }
}
