import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infobip_mobilemessaging_huawei/infobip_mobilemessaging_huawei.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  static const _applicationCode = String.fromEnvironment(
    'INFOBIP_APPLICATION_CODE',
  );
  String _status = _applicationCode.isEmpty
      ? 'Provide INFOBIP_APPLICATION_CODE with --dart-define.'
      : 'Ready to initialize.';
  bool _loading = false;

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _status = 'Initializing…';
    });
    try {
      await InfobipMobileMessagingHuawei.initialize(
        applicationCode: _applicationCode,
      );
      if (mounted) {
        setState(() => _status = 'Initialization succeeded.');
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _status = 'Initialization failed (${error.code}).',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infobip Huawei Plugin',
      home: Scaffold(
        appBar: AppBar(title: const Text('Infobip Huawei Plugin')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_status),
              const SizedBox(height: 16),
              if (_loading)
                const CircularProgressIndicator()
              else
                FilledButton(
                  onPressed: _applicationCode.isEmpty ? null : _initialize,
                  child: const Text('Initialize SDK'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
