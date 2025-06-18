import 'package:flutter_test/flutter_test.dart';
import 'package:ussd_flutter_package/ussd_flutter_package.dart';
import 'package:flutter/services.dart';
import 'package:ussd_flutter_package/ussd_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UssdFlutterPackage', () {
    const MethodChannel channel = MethodChannel('ussd_flutter_package');
    late List<MethodCall> log;

    setUp(() {
      log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return '42';
          case 'sendUssd':
            return {'message': 'USSD response from mock', 'state': 'continued'};
          case 'sendResponse':
            return {'message': 'Response sent from mock', 'state': 'continued'};
          case 'isUssdSupported':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getPlatformVersion returns correct version', () async {
      final version = await UssdFlutterPackage.getPlatformVersion();
      expect(version, '42');
    });

    test('sendUssd sends correct method call and returns UssdResponse',
        () async {
      const ussdCode = '*123#';
      final response = await UssdFlutterPackage.sendUssd(ussdCode);

      expect(log, <Matcher>[
        isMethodCall('sendUssd', arguments: {'ussdCode': ussdCode}),
      ]);
      expect(response.message, 'USSD response from mock');
      expect(response.state, UssdSessionState.continued);
    });

    test('sendResponse sends correct method call and returns UssdResponse',
        () async {
      const responseText = '1';
      final response = await UssdFlutterPackage.sendResponse(responseText);

      expect(log, <Matcher>[
        isMethodCall('sendResponse', arguments: {'response': responseText}),
      ]);
      expect(response.message, 'Response sent from mock');
      expect(response.state, UssdSessionState.continued);
    });

    test('isUssdSupported sends correct method call and returns boolean',
        () async {
      final isSupported = await UssdFlutterPackage.isUssdSupported();

      expect(log, <Matcher>[
        isMethodCall('isUssdSupported', arguments: null),
      ]);
      expect(isSupported, true);
    });

    test('ussdResponseStream receives events', () async {
      const EventChannel eventChannel =
          EventChannel('ussd_flutter_package/events');

      // Simulate an event coming from the native side
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        eventChannel.name,
        eventChannel.codec.encodeSuccessEnvelope(
            {'message': 'New USSD event', 'state': 'started'}),
        (ByteData? data) {/* do nothing */},
      );

      final response = await UssdFlutterPackage.ussdResponseStream.first;
      expect(response.message, 'New USSD event');
      expect(response.state, UssdSessionState.started);
    });
  });
}
