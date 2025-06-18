# ussd_flutter_package

A Flutter plugin for handling USSD (Unstructured Supplementary Service Data) requests and responses.

## Features

- Send USSD codes.
- Receive and process USSD responses (Android only).
- Send responses to interactive USSD sessions (Android only).
- Check if USSD is supported on the current device.

## Platform Support

| Platform | Send USSD | Receive/Process Responses | Send Interactive Responses |
|----------|-----------|---------------------------|----------------------------|
| Android  | ✅ Yes    | ✅ Yes                    | ✅ Yes                     |
| iOS      | ✅ Yes    | ❌ No                     | ❌ No                      |

**Note for iOS:** Due to platform limitations and security restrictions, direct interaction with USSD sessions (receiving responses or sending interactive responses) is not possible for third-party applications. On iOS, this plugin can only open the dialer with the USSD code, and the user will have to manually interact with the USSD session.

## Installation

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  ussd_flutter_package:
    git:
      url: https://github.com/YOUR_USERNAME/ussd_flutter_package.git # Replace with your repository URL
      ref: main # Or the branch/tag you want to use
```

Or, if you want to use it directly from your local path during development:

```yaml
dependencies:
  ussd_flutter_package:
    path: ../ussd_flutter_package # Adjust path as needed
```

Then run `flutter pub get`.

## Android Setup

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

## Usage

```dart
import 'package:ussd_flutter_package/ussd_flutter_package.dart';
import 'package:ussd_flutter_package/ussd_service.dart'; // For UssdResponse and UssdSessionState

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final UssdService _ussdService = UssdService();
  String _ussdResult = 'No USSD response yet.';

  @override
  void initState() {
    super.initState();
    _ussdService.ussdResponseStream.listen((response) {
      setState(() {
        _ussdResult = 'Message: ${response.message}\nState: ${response.state}';
      });
    }, onError: (error) {
      setState(() {
        _ussdResult = 'Error: ${error.message}';
      });
    });
  }

  Future<void> _sendUssdCode(String ussdCode) async {
    try {
      final response = await _ussdService.sendUssd(ussdCode);
      setState(() {
        _ussdResult = 'Message: ${response.message}\nState: ${response.state}';
      });
    } catch (e) {
      setState(() {
        _ussdResult = 'Error sending USSD: $e';
      });
    }
  }

  Future<void> _sendUssdResponse(String response) async {
    try {
      final ussdResponse = await _ussdService.sendResponse(response);
      setState(() {
        _ussdResult = 'Message: ${ussdResponse.message}\nState: ${ussdResponse.state}';
      });
    } catch (e) {
      setState(() {
        _ussdResult = 'Error sending response: $e';
      });
    }
  }

  Future<void> _checkUssdSupport() async {
    try {
      final isSupported = await _ussdService.isUssdSupported();
      setState(() {
        _ussdResult = 'USSD Supported: $isSupported';
      });
    } catch (e) {
      setState(() {
        _ussdResult = 'Error checking USSD support: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('USSD Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _sendUssdCode('*100#'),
                child: const Text('Send *100# (Balance Check)'),
              ),
              ElevatedButton(
                onPressed: () => _sendUssdCode('*123*1#'),
                child: const Text('Send *123*1# (Example Menu)'),
              ),
              ElevatedButton(
                onPressed: () => _sendUssdResponse('1'), // For interactive sessions
                child: const Text('Send Response (e.g., 1)'),
              ),
              ElevatedButton(
                onPressed: _checkUssdSupport,
                child: const Text('Check USSD Support'),
              ),
              SizedBox(height: 20),
              Text(_ussdResult),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.


