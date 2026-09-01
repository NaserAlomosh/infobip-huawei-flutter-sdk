import 'push_message.dart';

/// A notification action selection and its related message.
final class NotificationActionEvent {
  const NotificationActionEvent({required this.actionId, required this.message});

  final String? actionId;
  final PushMessage message;
}

/// A change to the SDK's push registration state.
final class RegistrationUpdatedEvent {
  const RegistrationUpdatedEvent({required this.isRegistrationEnabled});

  final bool isRegistrationEnabled;
}
