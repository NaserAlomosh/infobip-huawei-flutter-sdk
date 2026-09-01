/// Gender values supported by Infobip user profiles.
enum Gender {
  male,
  female,

  /// A gender value returned by native code that this plugin does not know.
  ///
  /// This value is read-only and cannot be sent in user updates because the
  /// native SDK accepts only its defined gender values.
  unknown,
}

/// Identifiers used to associate an installation with an Infobip user.
final class UserIdentity {
  const UserIdentity({this.externalUserId, this.phones, this.emails});

  final String? externalUserId;
  final List<String>? phones;
  final List<String>? emails;
}

/// Profile values that may be supplied while personalizing an installation.
final class UserAttributes {
  const UserAttributes({
    this.firstName,
    this.lastName,
    this.middleName,
    this.gender,
    this.birthday,
    this.tags,
    this.customAttributes,
  });

  final String? firstName;
  final String? lastName;
  final String? middleName;
  final Gender? gender;
  final DateTime? birthday;
  final List<String>? tags;

  /// Custom values supported by the native SDK.
  ///
  /// Values may be strings, booleans, numbers, [DateTime] instances, or lists
  /// containing those types. A [DateTime] is stored as a native date and
  /// round-trips as the same UTC instant.
  final Map<String, Object?>? customAttributes;
}

/// A Mobile Messaging user profile.
final class User {
  const User({
    this.externalUserId,
    this.firstName,
    this.lastName,
    this.middleName,
    this.gender,
    this.birthday,
    this.phones,
    this.emails,
    this.tags,
    this.customAttributes,
  });

  final String? externalUserId;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final Gender? gender;

  /// A date-only value. Its time and time zone components are not sent.
  final DateTime? birthday;
  final List<String>? phones;
  final List<String>? emails;
  final List<String>? tags;

  /// Custom values supported by the native SDK.
  ///
  /// Values may be strings, booleans, numbers, [DateTime] instances, or lists
  /// containing those scalar types. A [DateTime] is stored as a native date
  /// and round-trips as the same UTC instant.
  final Map<String, Object?>? customAttributes;
}
