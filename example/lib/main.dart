import 'dart:async';

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
  bool _initialized = false;
  bool? _registrationEnabled;
  final List<String> _events = [];
  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      InfobipMobileMessagingHuawei.notifications.onMessageReceived.listen(
        (message) =>
            _addEvent('Message received: ${message.messageId ?? 'unknown'}'),
      ),
      InfobipMobileMessagingHuawei.notifications.onNotificationTapped.listen(
        (message) => _addEvent(
          'Notification tapped: ${message.messageId ?? 'unknown'}',
        ),
      ),
      InfobipMobileMessagingHuawei
          .notifications
          .onNotificationActionTapped
          .listen(
            (event) =>
                _addEvent('Action tapped: ${event.actionId ?? 'unknown'}'),
          ),
      InfobipMobileMessagingHuawei.notifications.onRegistrationUpdated.listen(
        (event) => _addEvent(
          'Registration updated: ${event.isRegistrationEnabled}',
        ),
      ),
    ]);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  void _addEvent(String event) {
    if (mounted) setState(() => _events.insert(0, event));
  }

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
        setState(() {
          _initialized = true;
          _status = 'Initialization succeeded.';
        });
        await _refreshRegistration();
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

  Future<void> _setRegistration(bool enabled) async {
    try {
      await InfobipMobileMessagingHuawei.notifications.setRegistration(
        enabled: enabled,
      );
      await _refreshRegistration();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _status = 'Registration failed (${error.code}).');
      }
    }
  }

  Future<void> _refreshRegistration() async {
    final enabled = await InfobipMobileMessagingHuawei.notifications
        .isRegistrationEnabled();
    if (mounted) setState(() => _registrationEnabled = enabled);
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
              if (_initialized) ...[
                const SizedBox(height: 16),
                Text('Push registration: ${_registrationEnabled ?? 'unknown'}'),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => _setRegistration(true),
                      child: const Text('Enable push'),
                    ),
                    OutlinedButton(
                      onPressed: () => _setRegistration(false),
                      child: const Text('Disable push'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._events.take(5).map(Text.new),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
