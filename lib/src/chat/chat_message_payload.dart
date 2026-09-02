/// A payload for sending a message through an embedded Chat view.
///
/// This is a send payload, not a received Chat message. Programmatic
/// attachments are intentionally not supported; use the native composer for
/// its attachment workflow.
final class InfobipHuaweiChatMessagePayload {
  const InfobipHuaweiChatMessagePayload.text(this.text);

  /// The non-empty text to send.
  final String text;

  Map<String, Object> toMap() {
    if (text.trim().isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be empty');
    }
    return <String, Object>{'text': text};
  }
}
