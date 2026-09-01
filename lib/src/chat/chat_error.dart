/// A failure affecting an embedded Infobip Chat view.
final class InfobipHuaweiChatError {
  const InfobipHuaweiChatError({required this.code, this.message});

  /// The stable category of the failure.
  final InfobipHuaweiChatErrorCode code;

  /// A non-sensitive, human-readable diagnostic message, when available.
  final String? message;
}

/// Stable error categories reported by an embedded Chat view.
enum InfobipHuaweiChatErrorCode {
  notInitialized,
  activityUnavailable,
  chatUnavailable,
  nativeError,
  unknown,
}
