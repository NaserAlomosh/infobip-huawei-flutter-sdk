package com.infobip.mobilemessaging.huawei.user

import com.infobip.mobilemessaging.huawei.plugin.ChannelContract
import org.infobip.mobile.messaging.User
import org.infobip.mobile.messaging.UserAttributes
import org.infobip.mobile.messaging.UserIdentity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

internal object UserMapper {
    private val dateFormat: SimpleDateFormat
        get() = SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).apply {
            isLenient = false
            timeZone = TimeZone.getTimeZone("UTC")
        }

    fun toMap(user: User): Map<String, Any?> = mapOf(
        ChannelContract.EXTERNAL_USER_ID to user.externalUserId,
        ChannelContract.FIRST_NAME to user.firstName,
        ChannelContract.LAST_NAME to user.lastName,
        ChannelContract.MIDDLE_NAME to user.middleName,
        ChannelContract.GENDER to user.gender?.name?.lowercase(Locale.ROOT),
        ChannelContract.BIRTHDAY to user.birthday?.let(dateFormat::format),
        ChannelContract.PHONES to user.phones?.toList(),
        ChannelContract.EMAILS to user.emails?.toList(),
        ChannelContract.TAGS to user.tags?.toList(),
        ChannelContract.CUSTOM_ATTRIBUTES to channelValue(user.customAttributes),
    )

    fun toUser(value: Any?): User {
        val map = requireMap(value, ChannelContract.USER)
        return User().apply {
            externalUserId = string(map, ChannelContract.EXTERNAL_USER_ID)
            firstName = string(map, ChannelContract.FIRST_NAME)
            lastName = string(map, ChannelContract.LAST_NAME)
            middleName = string(map, ChannelContract.MIDDLE_NAME)
            gender = gender(map[ChannelContract.GENDER])
            birthday = date(map[ChannelContract.BIRTHDAY])
            phones = strings(map, ChannelContract.PHONES)?.toSet()
            emails = strings(map, ChannelContract.EMAILS)?.toSet()
            tags = strings(map, ChannelContract.TAGS)?.toSet()
            customAttributes = customAttributes(map[ChannelContract.CUSTOM_ATTRIBUTES])
        }
    }

    fun toIdentity(value: Any?): UserIdentity {
        val map = requireMap(value, ChannelContract.USER_IDENTITY)
        return UserIdentity().apply {
            externalUserId = string(map, ChannelContract.EXTERNAL_USER_ID)
            phones = strings(map, ChannelContract.PHONES)?.toSet()
            emails = strings(map, ChannelContract.EMAILS)?.toSet()
        }
    }

    fun toAttributes(value: Any?): UserAttributes? {
        if (value == null) return null
        val map = requireMap(value, ChannelContract.USER_ATTRIBUTES)
        return UserAttributes().apply {
            firstName = string(map, ChannelContract.FIRST_NAME)
            lastName = string(map, ChannelContract.LAST_NAME)
            middleName = string(map, ChannelContract.MIDDLE_NAME)
            gender = gender(map[ChannelContract.GENDER])
            birthday = date(map[ChannelContract.BIRTHDAY])
            tags = strings(map, ChannelContract.TAGS)?.toSet()
            customAttributes = customAttributes(map[ChannelContract.CUSTOM_ATTRIBUTES])
        }
    }

    private fun requireMap(value: Any?, name: String): Map<*, *> =
        value as? Map<*, *> ?: throw IllegalArgumentException("$name must be a map")

    private fun string(map: Map<*, *>, key: String): String? {
        val value = map[key] ?: return null
        return value as? String ?: throw IllegalArgumentException("$key must be a string")
    }

    private fun strings(map: Map<*, *>, key: String): List<String>? {
        val value = map[key] ?: return null
        val values = value as? List<*> ?: throw IllegalArgumentException("$key must be a list")
        if (values.any { it !is String }) throw IllegalArgumentException("$key must contain strings")
        return values.filterIsInstance<String>()
    }

    private fun gender(value: Any?): User.Gender? = when (value) {
        null -> null
        "male" -> User.Gender.Male
        "female" -> User.Gender.Female
        else -> throw IllegalArgumentException("gender is invalid")
    }

    private fun date(value: Any?): Date? {
        if (value == null) return null
        if (value !is String) throw IllegalArgumentException("birthday must be a string")
        return dateFormat.parse(value) ?: throw IllegalArgumentException("birthday is invalid")
    }

    @Suppress("UNCHECKED_CAST")
    private fun customAttributes(value: Any?): Map<String, Any?>? {
        if (value == null) return null
        val map = value as? Map<*, *>
            ?: throw IllegalArgumentException("customAttributes must be a map")
        if (map.keys.any { it !is String }) {
            throw IllegalArgumentException("customAttributes keys must be strings")
        }
        map.values.forEach(::validateChannelValue)
        return map as Map<String, Any?>
    }

    private fun validateChannelValue(value: Any?) {
        when (value) {
            null, is String, is Boolean, is Number -> Unit
            is List<*> -> value.forEach(::validateChannelValue)
            else -> throw IllegalArgumentException("customAttributes contains an unsupported value")
        }
    }

    private fun channelValue(value: Any?): Any? = when (value) {
        null, is String, is Boolean, is Number -> value
        is Date -> value.toInstant().toString()
        is List<*> -> value.map(::channelValue)
        is Set<*> -> value.map(::channelValue)
        is Map<*, *> -> value.entries.associate { (key, item) ->
            (key as? String ?: throw IllegalArgumentException("Unsupported native user payload")) to
                channelValue(item)
        }
        else -> throw IllegalArgumentException("Unsupported native user payload")
    }
}
