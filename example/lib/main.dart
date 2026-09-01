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
  final List<String> _events = [];
  final List<StreamSubscription<Object?>> _subscriptions = [];
  User? _user;

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

  Future<void> _loadUser({required bool fetch}) async {
    setState(() => _loading = true);
    try {
      final user = fetch
          ? await InfobipMobileMessagingHuawei.fetchUser()
          : await InfobipMobileMessagingHuawei.getUser();
      if (mounted) setState(() => _user = user);
    } on PlatformException catch (error) {
      if (mounted) setState(() => _status = 'User operation failed (${error.code}).');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _depersonalize() async {
    setState(() => _loading = true);
    try {
      await InfobipMobileMessagingHuawei.depersonalize();
      if (mounted) setState(() => _user = null);
    } on PlatformException catch (error) {
      if (mounted) setState(() => _status = 'Depersonalization failed (${error.code}).');
    } finally {
      if (mounted) setState(() => _loading = false);
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
              if (_initialized) ...[
                const SizedBox(height: 16),
                const Text('Listening for notification events.'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _loading ? null : () => _loadUser(fetch: false),
                      child: const Text('Local user'),
                    ),
                    OutlinedButton(
                      onPressed: _loading ? null : () => _loadUser(fetch: true),
                      child: const Text('Fetch user'),
                    ),
                    OutlinedButton(
                      onPressed: _loading ? null : _depersonalize,
                      child: const Text('Depersonalize'),
                    ),
                  ],
                ),
                Text(
                  _user == null
                      ? 'No user loaded.'
                      : 'User loaded (${_user!.tags?.length ?? 0} tags).',
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
