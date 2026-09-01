package com.infobip.mobilemessaging.huawei.inbox

import com.infobip.mobilemessaging.huawei.plugin.ChannelContract
import java.time.Instant
import java.util.Date

internal object InboxMapper {
    fun parseOptions(value: Any?): InboxOptions {
        if (value == null) return InboxOptions()
        val map = value as? Map<*, *> ?: throw IllegalArgumentException("options must be a map")
        val from = instant(map[ChannelContract.FROM], ChannelContract.FROM)
        val to = instant(map[ChannelContract.TO], ChannelContract.TO)
        if (from != null && to != null && from.after(to)) {
            throw IllegalArgumentException("from must not be after to")
        }
        val topic = optionalString(map, ChannelContract.TOPIC)?.also {
            if (it.isBlank()) throw IllegalArgumentException("topic must not be empty")
        }
        val limit = (map[ChannelContract.LIMIT] as? Number)?.toInt().also {
            if (map[ChannelContract.LIMIT] != null && it == null) {
                throw IllegalArgumentException("limit must be an integer")
            }
            if (it != null && it <= 0) throw IllegalArgumentException("limit must be positive")
        }
        return InboxOptions(from, to, topic, limit)
    }

    fun messageIds(value: Any?): List<String> {
        val values = value as? List<*> ?: throw IllegalArgumentException("messageIds must be a list")
        if (values.isEmpty() || values.any { it !is String || it.isBlank() }) {
            throw IllegalArgumentException("messageIds must contain non-empty strings")
        }
        return values.filterIsInstance<String>()
    }

    fun inbox(value: Any): Map<String, Any?> = mapOf(
        ChannelContract.COUNT_TOTAL to requiredNumber(value, "getCountTotal").toInt(),
        ChannelContract.COUNT_UNREAD to requiredNumber(value, "getCountUnread").toInt(),
        ChannelContract.MESSAGES to (getter(value, "getMessages") as? Iterable<*>)
            ?.filterNotNull()?.map(::message).orEmpty(),
    )

    internal fun message(value: Any): Map<String, Any?> = mapOf(
        ChannelContract.MESSAGE_ID to requiredString(value, "getMessageId"),
        ChannelContract.TITLE to getter(value, "getTitle") as? String,
        ChannelContract.BODY to getter(value, "getBody") as? String,
        ChannelContract.TOPIC to getter(value, "getTopic") as? String,
        ChannelContract.SEEN to (getter(value, "isSeen") as? Boolean ?: false),
        ChannelContract.RECEIVED_TIMESTAMP to timestamp(getter(value, "getReceivedTimestamp")),
        ChannelContract.CUSTOM_PAYLOAD to safeMap(getter(value, "getCustomPayload")),
        ChannelContract.DEEP_LINK to getter(value, "getDeeplink") as? String,
        ChannelContract.IS_SILENT to (getter(value, "isSilent") as? Boolean ?: false),
    )

    private fun optionalString(map: Map<*, *>, key: String): String? {
        val value = map[key] ?: return null
        return value as? String ?: throw IllegalArgumentException("$key must be a string")
    }

    private fun instant(value: Any?, key: String): Date? {
        if (value == null) return null
        if (value !is String) throw IllegalArgumentException("$key must be a timestamp")
        return try {
            Date.from(Instant.parse(value))
        } catch (_: Exception) {
            throw IllegalArgumentException("$key must be a UTC timestamp")
        }
    }

    private fun getter(value: Any, name: String): Any? =
        value.javaClass.methods.firstOrNull { it.name == name && it.parameterCount == 0 }?.invoke(value)

    private fun requiredString(value: Any, name: String): String =
        getter(value, name) as? String ?: throw IllegalArgumentException("Invalid Inbox message")

    private fun requiredNumber(value: Any, name: String): Number =
        getter(value, name) as? Number ?: throw IllegalArgumentException("Invalid Inbox result")

    private fun timestamp(value: Any?): String? = when (value) {
        is Date -> value.toInstant().toString()
        is Number -> Instant.ofEpochMilli(value.toLong()).toString()
        else -> null
    }

    private fun safeMap(value: Any?): Map<String, Any?> {
        val map = value as? Map<*, *> ?: return emptyMap()
        return map.entries.mapNotNull { (key, item) ->
            val stringKey = key as? String ?: return@mapNotNull null
            stringKey to safeValue(item)
        }.toMap()
    }

    private fun safeValue(value: Any?): Any? = when (value) {
        null, is String, is Boolean, is Int, is Long, is Double, is Float -> value
        is Map<*, *> -> safeMap(value)
        is Iterable<*> -> value.map(::safeValue)
        is Array<*> -> value.map(::safeValue)
        else -> null
    }
}

internal data class InboxOptions(
    val from: Date? = null,
    val to: Date? = null,
    val topic: String? = null,
    val limit: Int? = null,
)
