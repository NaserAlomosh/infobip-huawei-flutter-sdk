import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infobip_mobilemessaging_huawei/infobip_mobilemessaging_huawei.dart';

import '../widgets/result_card.dart';
import '../widgets/section_card.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _externalUserId = TextEditingController();
  final _jwt = TextEditingController();
  final _topic = TextEditingController();
  final _limit = TextEditingController(text: '20');
  Inbox? _inbox;
  bool _loading = false;
  String _result = 'Enter a test identity and an optional temporary JWT.';

  Future<void> _fetch() async {
    if (_loading) return;
    final limit = int.tryParse(_limit.text.trim());
    if (limit == null || limit <= 0) {
      setState(() => _result = 'Limit must be a positive integer.');
      return;
    }
    setState(() => _loading = true);
    try {
      final inbox = await InfobipMobileMessagingHuawei.fetchInbox(
        externalUserId: _externalUserId.text.trim(),
        jwt: _jwt.text.trim().isEmpty ? null : _jwt.text.trim(),
        options: InboxFilterOptions(
          limit: limit,
          topic: _topic.text.trim().isEmpty ? null : _topic.text.trim(),
        ),
      );
      if (mounted) {
        setState(() {
          _inbox = inbox;
          _result = 'Inbox fetch succeeded.';
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _result =
              '${error.code}: ${error.message ?? 'Inbox operation failed'}',
        );
      }
    } on ArgumentError catch (error) {
      if (mounted) setState(() => _result = error.message.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markSeen(InboxMessage message) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await InfobipMobileMessagingHuawei.setInboxMessagesSeen(
        externalUserId: _externalUserId.text.trim(),
        messageIds: [message.messageId],
      );
      if (mounted) {
        setState(() => _result = 'Message marked seen on the server.');
      }
      await _fetchAfterUpdate();
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _result =
              '${error.code}: ${error.message ?? 'Inbox update failed'}',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchAfterUpdate() async {
    final inbox = await InfobipMobileMessagingHuawei.fetchInbox(
      externalUserId: _externalUserId.text.trim(),
      jwt: _jwt.text.trim().isEmpty ? null : _jwt.text.trim(),
      options: InboxFilterOptions(
        limit: int.tryParse(_limit.text.trim()),
        topic: _topic.text.trim().isEmpty ? null : _topic.text.trim(),
      ),
    );
    if (mounted) setState(() => _inbox = inbox);
  }

  @override
  void dispose() {
    _externalUserId.dispose();
    _jwt.dispose();
    _topic.dispose();
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inbox = _inbox;
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            SectionCard(
              title: 'Fetch Inbox',
              description:
                  'The JWT is obscured, used only for this request, and never '
                  'stored or logged.',
              children: [
                TextField(
                  controller: _externalUserId,
                  decoration: const InputDecoration(
                    labelText: 'Test external user ID',
                  ),
                ),
                TextField(
                  controller: _jwt,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Temporary JWT (optional)',
                  ),
                ),
                TextField(
                  controller: _topic,
                  decoration: const InputDecoration(
                    labelText: 'Topic filter (optional)',
                  ),
                ),
                TextField(
                  controller: _limit,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Limit'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _loading ? null : _fetch,
                  child: const Text('Fetch Inbox'),
                ),
              ],
            ),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (inbox != null) ...[
              ResultCard(
                title: 'Counters',
                message:
                    'Total: ${inbox.countTotal}\n'
                    'Unread: ${inbox.countUnread}\n'
                    'Filtered: ${inbox.countTotalFiltered}\n'
                    'Filtered unread: ${inbox.countUnreadFiltered}',
              ),
              ...inbox.messages.map(
                (message) => Card(
                  child: ListTile(
                    title: Text(message.title ?? 'Untitled message'),
                    subtitle: Text(
                      [
                        if (message.body != null) message.body!,
                        'Topic: ${message.topic ?? 'none'}',
                        'Received: ${message.receivedTimestamp?.toLocal() ?? 'unknown'}',
                      ].join('\n'),
                    ),
                    trailing: message.seen
                        ? const Icon(
                            Icons.drafts_outlined,
                            semanticLabel: 'Seen',
                          )
                        : TextButton(
                            onPressed: _loading
                                ? null
                                : () => _markSeen(message),
                            child: const Text('Mark seen'),
                          ),
                  ),
                ),
              ),
            ],
            ResultCard(title: 'Result', message: _result),
          ],
        ),
      ),
    );
  }
}
