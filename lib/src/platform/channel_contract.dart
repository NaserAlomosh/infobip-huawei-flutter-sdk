abstract final class ChannelContract {
  static const methodChannel = 'com.infobip.mobilemessaging.huawei/methods';
  static const eventChannel = 'com.infobip.mobilemessaging.huawei/events';
  static const initialize = 'initialize';
  static const setRegistration = 'setRegistration';
  static const isRegistrationEnabled = 'isRegistrationEnabled';
  static const applicationCode = 'applicationCode';
  static const enabled = 'enabled';

  static const eventVersion = 1;
  static const messageReceived = 'message_received';
  static const notificationTapped = 'notification_tapped';
  static const notificationActionTapped = 'notification_action_tapped';
  static const registrationUpdated = 'registration_updated';
}
