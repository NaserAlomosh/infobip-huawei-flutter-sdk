package com.infobip.mobilemessaging.huawei.plugin

import org.infobip.mobile.messaging.Message

internal object MessageMapper {
    fun map(message: Message): Map<String, Any?> = mapOf(
        "messageId" to message.messageId,
        "title" to message.title,
        "body" to message.body,
        "customPayload" to channelSafeMap(message.customPayload),
        "deepLink" to message.deeplink,
        "isSilent" to message.isSilent,
    )

    private fun channelSafeMap(value: Map<String, *>?): Map<String, Any?> =
        value?.mapValues { channelSafe(it.value) } ?: emptyMap()

    private fun channelSafe(value: Any?): Any? = when (value) {
        null, is String, is Boolean, is Int, is Long, is Double, is Float -> value
        is Map<*, *> -> value.entries.associate { it.key.toString() to channelSafe(it.value) }
        is Iterable<*> -> value.map(::channelSafe)
        is Array<*> -> value.map(::channelSafe)
        else -> null
    }
}
