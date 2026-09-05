import '../installation/installation.dart';

// Names intentionally match the official Infobip Flutter API.
// ignore_for_file: constant_identifier_names

enum Gender {
  Male,
  Female,
  unknown;

  @Deprecated('Use Gender.Male')
  static const male = Male;
  @Deprecated('Use Gender.Female')
  static const female = Female;
}

enum Type { Lead, Customer, unknown }

final class UserIdentity {
  const UserIdentity({this.externalUserId, this.phones, this.emails});
  final String? externalUserId;
  final List<String>? phones;
  final List<String>? emails;
}

final class UserAttributes {
  const UserAttributes({
    this.firstName,
    this.lastName,
    this.middleName,
    this.gender,
    this.birthday,
    this.type,
    this.tags,
    this.customAttributes,
  });
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final Gender? gender;
  final DateTime? birthday;
  final Type? type;
  final List<String>? tags;
  final Map<String, Object?>? customAttributes;
}

/// A Mobile Messaging user profile.
final class UserData {
  const UserData({
    this.externalUserId,
    this.firstName,
    this.lastName,
    this.middleName,
    this.gender,
    this.birthday,
    this.type,
    this.phones,
    this.emails,
    this.tags,
    this.customAttributes,
    this.installations,
  });
  final String? externalUserId;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final Gender? gender;
  final DateTime? birthday;
  final Type? type;
  final List<String>? phones;
  final List<String>? emails;
  final List<String>? tags;
  final Map<String, Object?>? customAttributes;
  final List<Installation>? installations;
}

/// Backwards-compatible name for [UserData].
@Deprecated('Use UserData')
typedef User = UserData;

/// Values used to personalize an installation.
final class PersonalizeContext {
  const PersonalizeContext({
    this.forceDepersonalize = false,
    required this.userIdentity,
    this.userAttributes,
  });
  final bool forceDepersonalize;
  final UserIdentity userIdentity;
  final UserAttributes? userAttributes;
}
