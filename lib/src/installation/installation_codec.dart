import '../platform/channel_contract.dart';
import '../user/user_codec.dart';
import 'installation.dart';

abstract final class InstallationCodec {
  static Installation decode(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid installation payload');
    }
    return Installation(
      installationId: _string(value, ChannelContract.installationId),
      pushRegistrationId: _string(value, ChannelContract.pushRegistrationId),
      pushRegistrationEnabled: _bool(
        value,
        ChannelContract.pushRegistrationEnabled,
      ),
      isPrimaryDevice: _bool(value, ChannelContract.isPrimaryDevice),
      notificationsEnabled: _bool(value, ChannelContract.notificationsEnabled),
      deviceManufacturer: _string(value, ChannelContract.deviceManufacturer),
      deviceModel: _string(value, ChannelContract.deviceModel),
      deviceSecure: _bool(value, ChannelContract.deviceSecure),
      applicationVersion: _string(value, ChannelContract.applicationVersion),
      operatingSystem: _string(value, ChannelContract.operatingSystem),
      operatingSystemVersion: _string(
        value,
        ChannelContract.operatingSystemVersion,
      ),
      language: _string(value, ChannelContract.language),
      deviceTimezoneId: _string(value, ChannelContract.deviceTimezoneId),
      sdkVersion: _string(value, ChannelContract.sdkVersion),
      appUserId: _string(value, ChannelContract.appUserId),
      customAttributes: UserCodec.decodeCustomAttributes(
        value[ChannelContract.customAttributes],
      ),
    );
  }

  /// Encodes only properties accepted by the native save API.
  static Map<String, Object?> encodeWritable(Installation value) => {
    ChannelContract.isPrimaryDevice: value.isPrimaryDevice,
    ChannelContract.customAttributes: UserCodec.encodeCustomAttributes(
      value.customAttributes,
    ),
  };

  static String? _string(Map value, String key) {
    final item = value[key];
    if (item == null || item is String) return item as String?;
    throw FormatException('$key must be a string');
  }

  static bool? _bool(Map value, String key) {
    final item = value[key];
    if (item == null || item is bool) return item as bool?;
    throw FormatException('$key must be a boolean');
  }
}
