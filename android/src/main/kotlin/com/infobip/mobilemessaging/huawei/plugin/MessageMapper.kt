package com.infobip.mobilemessaging.huawei.plugin

import org.infobip.mobile.messaging.Message
import org.json.JSONArray
import org.json.JSONObject

internal object MessageMapper {
    fun map(message: Message): Map<String, Any?> =
        mapOf(
            "messageId" to message.messageId,
            "title" to message.title,
            "body" to message.body,
            "customPayload" to channelSafeObject(message.customPayload),
            "deepLink" to message.deeplink,
            "isSilent" to message.isSilent,
        )

    private fun channelSafeObject(value: JSONObject?): Map<String, Any?> =
        value?.keys()?.asSequence()?.associateWith { key -> channelSafe(value.opt(key)) } ?: emptyMap()

    private fun channelSafeArray(value: JSONArray): List<Any?> = (0 until value.length()).map { index -> channelSafe(value.opt(index)) }

    private fun channelSafe(value: Any?): Any? =
        when (value) {
            null, JSONObject.NULL -> {
                null
            }

            is String, is Boolean, is Int, is Long, is Double -> {
                value
            }

            is Float -> {
                value.toDouble()
            }

            is JSONObject -> {
                channelSafeObject(value)
            }

            is JSONArray -> {
                channelSafeArray(value)
            }

            is Map<*, *> -> {
                value.entries
                    .mapNotNull { (key, item) ->
                        (key as? String)?.let { it to channelSafe(item) }
                    }.toMap()
            }

            is Iterable<*> -> {
                value.map(::channelSafe)
            }

            is Array<*> -> {
                value.map(::channelSafe)
            }

            else -> {
                null
            }
        }
}
