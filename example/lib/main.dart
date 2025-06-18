import 'package:flutter/material.dart';
import 'package:ussd_flutter_package/ussd_flutter_package.dart';
import 'package:ussd_flutter_package/ussd_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final UssdService _ussdService = UssdService();

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();

  String _ussdMessage = 'No USSD response yet.';
  bool _waitingForResponse = false;
  List<String> _options = [];

  @override
  void initState() {
    super.initState();
    _ussdService.ussdResponseStream.listen((response) {
      setState(() {
        _ussdMessage = response.message;
        if (response.state == 'waiting_for_response') {
          _waitingForResponse = true;
          _options = _parseOptions(response.message);
        } else {
          _waitingForResponse = false;
          _options.clear();
        }
      });
    });
  }

  List<String> _parseOptions(String message) {
    // تقطيع الرسالة إلى خيارات بناءً على سطر جديد أو أرقام
    final lines = message.split('\n');
    return lines.where((line) => line.trim().isNotEmpty).toList();
  }

  Future<void> _sendUssdCode() async {
    setState(() {
      _waitingForResponse = false;
      _options.clear();
      _ussdMessage = 'Sending USSD code...';
    });
    try {
      await _ussdService.sendUssd(_codeController.text);
    } catch (e) {
      setState(() {
        _ussdMessage = 'Error sending USSD: $e';
      });
    }
  }

  Future<void> _sendResponse(String response) async {
    try {
      await _ussdService.sendResponse(response);
      setState(() {
        _waitingForResponse = false;
        _options.clear();
        _ussdMessage = 'Response sent, waiting for next...';
      });
    } catch (e) {
      setState(() {
        _ussdMessage = 'Error sending response: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('USSD Interactive Demo')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Enter USSD code (e.g. *140#)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _sendUssdCode,
                child: const Text('Send USSD Code'),
              ),
              const SizedBox(height: 20),
              if (_waitingForResponse) ...[
                const Text('Choose an option:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ..._options.map((option) {
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      // ترسل الرد كخيار
                      _sendResponse(option);
                    },
                  );
                }),
              ],
              const SizedBox(height: 20),
              Text('USSD Message:'),
              Text(_ussdMessage),
            ],
          ),
        ),
      ),
    );
  }
}
