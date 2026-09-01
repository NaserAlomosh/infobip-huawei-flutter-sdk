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
  static const _inboxExternalUserId = String.fromEnvironment(
    'INFOBIP_INBOX_EXTERNAL_USER_ID',
  );
  String _status = _applicationCode.isEmpty
      ? 'Provide INFOBIP_APPLICATION_CODE with --dart-define.'
      : 'Ready to initialize.';
  bool _loading = false;
  bool _initialized = false;
  final List<String> _events = [];
  final List<StreamSubscription<Object?>> _subscriptions = [];
  User? _user;
  Installation? _installation;
  Inbox? _inbox;

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
        (installation) => _addEvent(
          'Registration updated: ${installation.pushRegistrationEnabled}',
        ),
      ),
      InfobipMobileMessagingHuawei.notifications.onInstallationUpdated.listen(
        (installation) => _addEvent(
          'Installation updated (language: ${installation.language ?? 'unset'}).',
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

  Future<void> _loadInstallation({required bool fetch}) async {
    setState(() => _loading = true);
    try {
      final installation = fetch
          ? await InfobipMobileMessagingHuawei.fetchInstallation()
          : await InfobipMobileMessagingHuawei.getInstallation();
      if (mounted) setState(() => _installation = installation);
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _status = 'Installation operation failed (${error.code}).');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveInstallation() async {
    final installation = _installation;
    if (installation == null) return;
    setState(() => _loading = true);
    try {
      final saved = await InfobipMobileMessagingHuawei.saveInstallation(
        Installation(
          isPrimaryDevice: installation.isPrimaryDevice,
          customAttributes: installation.customAttributes,
        ),
      );
      if (mounted) setState(() => _installation = saved);
    } on PlatformException catch (error) {
      if (mounted) setState(() => _status = 'Installation save failed (${error.code}).');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchInbox() async {
    setState(() => _loading = true);
    try {
      final inbox = await InfobipMobileMessagingHuawei.fetchInbox(
        externalUserId: _inboxExternalUserId,
        options: const InboxFilterOptions(limit: 20),
      );
      if (mounted) setState(() => _inbox = inbox);
    } on PlatformException catch (error) {
      if (mounted) setState(() => _status = 'Inbox fetch failed (${error.code}).');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markFirstInboxMessageSeen() async {
    final message = _inbox?.messages.where((item) => !item.seen).firstOrNull;
    if (message == null) return;
    setState(() => _loading = true);
    try {
      await InfobipMobileMessagingHuawei.setInboxMessagesSeen(
        externalUserId: _inboxExternalUserId,
        messageIds: [message.messageId],
      );
      await _fetchInbox();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _status = 'Inbox update failed (${error.code}).');
      }
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
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _loading || _inboxExternalUserId.isEmpty
                          ? null
                          : _fetchInbox,
                      child: const Text('Fetch Inbox'),
                    ),
                    OutlinedButton(
                      onPressed: _loading ||
                              _inboxExternalUserId.isEmpty ||
                              !(_inbox?.messages.any(
                                    (message) => !message.seen,
                                  ) ??
                                  false)
                          ? null
                          : _markFirstInboxMessageSeen,
                      child: const Text('Mark first unseen as seen'),
                    ),
                  ],
                ),
                Text(
                  _inbox == null
                      ? 'No Inbox loaded.'
                      : 'Inbox: ${_inbox!.countTotal} total, '
                            '${_inbox!.countUnread} unread.',
                ),
                ...?_inbox?.messages.take(5).map(
                  (message) => ListTile(
                    title: Text(message.title ?? 'Untitled message'),
                    subtitle: Text(message.body ?? ''),
                    trailing: Icon(
                      message.seen ? Icons.drafts_outlined : Icons.mail_outline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => _loadInstallation(fetch: false),
                      child: const Text('Local installation'),
                    ),
                    OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => _loadInstallation(fetch: true),
                      child: const Text('Fetch installation'),
                    ),
                    OutlinedButton(
                      onPressed: _loading || _installation == null
                          ? null
                          : _saveInstallation,
                      child: const Text('Save installation'),
                    ),
                  ],
                ),
                Text(
                  _installation == null
                      ? 'No installation loaded.'
                      : 'Registration enabled: '
                            '${_installation!.pushRegistrationEnabled ?? 'unknown'}',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Open embedded Chat'),
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

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = InfobipHuaweiChatController();

  Future<void> _back() async {
    final handled = await _controller.navigateBackOrCloseChat();
    if (!handled && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (_, _) => _back(),
    child: Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _back),
        title: const Text('Chat'),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Flutter business action')),
            ),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Business action',
          ),
        ],
      ),
      body: InfobipHuaweiChatView(controller: _controller),
    ),
  );
}
