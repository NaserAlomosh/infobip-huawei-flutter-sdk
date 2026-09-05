/// An Infobip installation associated with this application instance.
///
/// Device, application, SDK, and registration identifier properties are
/// managed by the native SDK. [isPrimaryDevice] and [customAttributes] may be
/// changed with `saveInstallation`.
final class Installation {
  const Installation({
    this.installationId,
    this.pushRegistrationId,
    this.pushRegistrationEnabled,
    this.isPrimaryDevice,
    this.notificationsEnabled,
    this.deviceManufacturer,
    this.deviceModel,
    this.deviceSecure,
    this.applicationVersion,
    this.operatingSystem,
    this.operatingSystemVersion,
    this.language,
    this.deviceTimezoneId,
    this.sdkVersion,
    this.appUserId,
    this.customAttributes,
  });

  final String? installationId;
  final String? pushRegistrationId;
  final bool? pushRegistrationEnabled;
  final bool? isPrimaryDevice;
  final bool? notificationsEnabled;
  final String? deviceManufacturer;
  final String? deviceModel;
  final bool? deviceSecure;
  final String? applicationVersion;
  final String? operatingSystem;
  final String? operatingSystemVersion;
  final String? language;
  final String? deviceTimezoneId;
  final String? sdkVersion;
  final String? appUserId;

  /// Strings, booleans, numbers, [DateTime] values, or lists of those values.
  final Map<String, Object?>? customAttributes;
}
