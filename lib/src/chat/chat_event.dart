/// Runtime events emitted by one embedded Chat view.
sealed class InfobipHuaweiChatEvent {
  const InfobipHuaweiChatEvent();
}

/// The Live Chat widget finished its native loading sequence.
final class InfobipHuaweiChatLoadedEvent extends InfobipHuaweiChatEvent {
  const InfobipHuaweiChatLoadedEvent();
}

/// A stable representation of the screen currently displayed by Chat.
enum InfobipHuaweiChatViewState {
  loading,
  threadList,
  loadingThread,
  thread,
  closedThread,
  singleModeThread,
  unknown,
}

/// Chat changed the screen displayed by this embedded view.
final class InfobipHuaweiChatViewChangedEvent extends InfobipHuaweiChatEvent {
  const InfobipHuaweiChatViewChangedEvent({
    required this.state,
    required this.rawValue,
  });

  final InfobipHuaweiChatViewState state;

  /// The Huawei SDK value, retained for forward compatibility.
  final String rawValue;
}

/// The connection state reported by the embedded Live Chat widget.
enum InfobipHuaweiChatConnectionState { connected, disconnected, unknown }

/// Chat resumed or paused its connection.
final class InfobipHuaweiChatConnectionChangedEvent
    extends InfobipHuaweiChatEvent {
  const InfobipHuaweiChatConnectionChangedEvent({
    required this.state,
    required this.rawValue,
  });

  final InfobipHuaweiChatConnectionState state;

  /// The native value, retained for forward compatibility.
  final String rawValue;
}
