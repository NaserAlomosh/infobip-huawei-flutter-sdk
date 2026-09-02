import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/channel_contract.dart';
import 'chat_error.dart';
import 'chat_message_payload.dart';

typedef InfobipHuaweiChatErrorCallback =
    void Function(InfobipHuaweiChatError error);

final class _ChatViewBridge {
  _ChatViewBridge(this.viewId, this._onError)
    : channel = MethodChannel('${ChannelContract.chatViewChannel}$viewId') {
    channel.setMethodCallHandler(_handleMethodCall);
    unawaited(channel.invokeMethod<void>(ChannelContract.chatViewReady));
  }

  final int viewId;
  final MethodChannel channel;
  InfobipHuaweiChatErrorCallback? _onError;

  void updateErrorCallback(InfobipHuaweiChatErrorCallback? callback) {
    _onError = callback;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != ChannelContract.chatOnError) return;
    _onError?.call(_decodeError(call.arguments));
  }

  void dispose() {
    _onError = null;
    channel.setMethodCallHandler(null);
  }
}

InfobipHuaweiChatError _decodeError(Object? payload) {
  if (payload is! Map) {
    return const InfobipHuaweiChatError(
      code: InfobipHuaweiChatErrorCode.unknown,
    );
  }
  final code = switch (payload[ChannelContract.code]) {
    'not_initialized' => InfobipHuaweiChatErrorCode.notInitialized,
    'activity_unavailable' => InfobipHuaweiChatErrorCode.activityUnavailable,
    'chat_unavailable' => InfobipHuaweiChatErrorCode.chatUnavailable,
    'native_error' => InfobipHuaweiChatErrorCode.nativeError,
    _ => InfobipHuaweiChatErrorCode.unknown,
  };
  final message = payload[ChannelContract.message];
  return InfobipHuaweiChatError(
    code: code,
    message: message is String ? message : null,
  );
}

/// Controls one [InfobipHuaweiChatView].
final class InfobipHuaweiChatController {
  _ChatViewBridge? _bridge;
  int? _viewId;

  /// Whether this controller is attached to a live native Chat view.
  bool get isAttached => _bridge != null;

  /// Sends a text message through this embedded Chat component.
  ///
  /// The native composer remains available and is the supported attachment
  /// workflow.
  Future<void> send(InfobipHuaweiChatMessagePayload payload) async {
    final bridge = _requireBridge();
    await bridge.channel.invokeMethod<void>(
      ChannelContract.chatSend,
      payload.toMap(),
    );
  }

  /// Sends opaque contextual data through this embedded Chat component.
  ///
  /// Contextual data is not displayed as a normal Chat message.
  Future<void> sendContextualData(String data) async {
    if (data.trim().isEmpty) {
      throw ArgumentError.value(data, 'data', 'must not be empty');
    }
    final bridge = _requireBridge();
    await bridge.channel.invokeMethod<void>(
      ChannelContract.chatSendContextualData,
      <String, Object>{ChannelContract.data: data},
    );
  }

  /// Sets the language used by this embedded Chat component.
  ///
  /// The value is a language identifier supported by the configured Infobip
  /// widget. It is forwarded to the native SDK and is not persisted by Dart.
  Future<void> setLanguage(String language) async {
    if (language.trim().isEmpty) {
      throw ArgumentError.value(language, 'language', 'must not be empty');
    }
    final bridge = _requireBridge();
    await bridge.channel.invokeMethod<void>(
      ChannelContract.chatSetLanguage,
      <String, Object>{ChannelContract.language: language},
    );
  }

  /// Returns the language currently reported by this Chat component.
  Future<String> getLanguage() async {
    final bridge = _requireBridge();
    final language = await bridge.channel.invokeMethod<String>(
      ChannelContract.chatGetLanguage,
    );
    if (language == null) {
      throw PlatformException(
        code: 'native_error',
        message: 'Chat language is unavailable',
      );
    }
    return language;
  }

  /// Sets the configured widget theme name for this Chat component.
  ///
  /// This is an Infobip widget theme identifier, not a Flutter [ThemeData]
  /// value or an Android resource identifier.
  Future<void> setWidgetTheme(String widgetTheme) async {
    if (widgetTheme.trim().isEmpty) {
      throw ArgumentError.value(
        widgetTheme,
        'widgetTheme',
        'must not be empty',
      );
    }
    final bridge = _requireBridge();
    await bridge.channel.invokeMethod<void>(
      ChannelContract.chatSetWidgetTheme,
      <String, Object>{ChannelContract.widgetTheme: widgetTheme},
    );
  }

  /// Returns the widget theme name currently reported by this component.
  Future<String?> getWidgetTheme() async {
    final bridge = _requireBridge();
    return bridge.channel.invokeMethod<String>(
      ChannelContract.chatGetWidgetTheme,
    );
  }

  /// Lets Chat consume its internal back navigation.
  ///
  /// Returns `false` when the controller is not attached. When it returns
  /// `false`, the Flutter route may be popped.
  Future<bool> navigateBackOrCloseChat() async {
    final bridge = _bridge;
    if (bridge == null) return false;
    final handled = await bridge.channel.invokeMethod<Object?>(
      ChannelContract.chatNavigateBack,
    );
    if (handled is! bool) {
      throw const FormatException('Invalid Chat navigation result');
    }
    return handled;
  }

  _ChatViewBridge _requireBridge() {
    final bridge = _bridge;
    if (bridge == null) {
      throw PlatformException(
        code: 'chat_unavailable',
        message: 'Chat view is unavailable',
      );
    }
    return bridge;
  }

  void _attach(_ChatViewBridge bridge) {
    final viewId = bridge.viewId;
    if (_viewId != null && _viewId != viewId) {
      throw StateError('A Chat controller can only control one active view.');
    }
    _viewId = viewId;
    _bridge = bridge;
  }

  void _detach(int? viewId) {
    if (_viewId != viewId) return;
    _viewId = null;
    _bridge = null;
  }
}

/// Embeds the Infobip native Chat UI inside Flutter-provided bounds.
///
/// The native view owns the message composer and attachments. Put this widget
/// in a Flutter [Scaffold] body to retain Flutter navigation and app bars.
class InfobipHuaweiChatView extends StatefulWidget {
  const InfobipHuaweiChatView({super.key, this.controller, this.onError});

  final InfobipHuaweiChatController? controller;

  /// Called for lifecycle and availability failures affecting this view.
  ///
  /// Controller command failures continue to complete their returned Future
  /// with a [PlatformException].
  final InfobipHuaweiChatErrorCallback? onError;

  @override
  State<InfobipHuaweiChatView> createState() => _InfobipHuaweiChatViewState();
}

class _InfobipHuaweiChatViewState extends State<InfobipHuaweiChatView> {
  int? _viewId;
  _ChatViewBridge? _bridge;

  @override
  void didUpdateWidget(InfobipHuaweiChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(_viewId);
      final viewId = _viewId;
      final bridge = _bridge;
      if (viewId != null && bridge != null) widget.controller?._attach(bridge);
    }
    _bridge?.updateErrorCallback(widget.onError);
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const Center(child: Text('Chat is available on Android only.'));
    }
    return AndroidView(
      viewType: ChannelContract.chatView,
      onPlatformViewCreated: (viewId) {
        widget.controller?._detach(_viewId);
        _bridge?.dispose();
        _viewId = viewId;
        final bridge = _ChatViewBridge(viewId, widget.onError);
        _bridge = bridge;
        widget.controller?._attach(bridge);
      },
    );
  }

  @override
  void dispose() {
    widget.controller?._detach(_viewId);
    _bridge?.dispose();
    _bridge = null;
    super.dispose();
  }
}
