import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/channel_contract.dart';

/// Controls one [InfobipHuaweiChatView].
final class InfobipHuaweiChatController {
  MethodChannel? _channel;
  int? _viewId;

  /// Whether this controller is attached to a live native Chat view.
  bool get isAttached => _channel != null;

  /// Lets Chat consume its internal back navigation.
  ///
  /// Returns `false` when the controller is not attached. When it returns
  /// `false`, the Flutter route may be popped.
  Future<bool> navigateBackOrCloseChat() async {
    final channel = _channel;
    if (channel == null) return false;
    return await channel.invokeMethod<bool>(ChannelContract.chatNavigateBack) ??
        false;
  }

  void _attach(int viewId) {
    if (_viewId != null && _viewId != viewId) {
      throw StateError('A Chat controller can only control one active view.');
    }
    _viewId = viewId;
    _channel = MethodChannel('${ChannelContract.chatViewChannel}$viewId');
  }

  void _detach(int? viewId) {
    if (_viewId != viewId) return;
    _viewId = null;
    _channel = null;
  }
}

/// Embeds the Infobip native Chat UI inside Flutter-provided bounds.
///
/// The native view owns the message composer and attachments. Put this widget
/// in a Flutter [Scaffold] body to retain Flutter navigation and app bars.
class InfobipHuaweiChatView extends StatefulWidget {
  const InfobipHuaweiChatView({super.key, this.controller});

  final InfobipHuaweiChatController? controller;

  @override
  State<InfobipHuaweiChatView> createState() => _InfobipHuaweiChatViewState();
}

class _InfobipHuaweiChatViewState extends State<InfobipHuaweiChatView> {
  int? _viewId;

  @override
  void didUpdateWidget(InfobipHuaweiChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(_viewId);
      final viewId = _viewId;
      if (viewId != null) widget.controller?._attach(viewId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const Center(child: Text('Chat is available on Android only.'));
    }
    return AndroidView(
      viewType: ChannelContract.chatView,
      onPlatformViewCreated: (viewId) {
        _viewId = viewId;
        widget.controller?._attach(viewId);
      },
    );
  }

  @override
  void dispose() {
    widget.controller?._detach(_viewId);
    super.dispose();
  }
}
