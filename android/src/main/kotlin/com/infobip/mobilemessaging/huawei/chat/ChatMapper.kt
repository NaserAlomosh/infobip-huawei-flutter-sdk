package com.infobip.mobilemessaging.huawei.chat

import com.infobip.mobilemessaging.huawei.plugin.ChannelContract
import org.infobip.mobile.messaging.chat.models.MessagePayload

internal object ChatMapper {
    fun messagePayload(arguments: Any?): MessagePayload {
        val text = value(arguments, ChannelContract.TEXT)
        require(text.isNotBlank()) { "Message text must not be empty" }
        return MessagePayload.Basic(text)
    }

    fun contextualData(arguments: Any?): String {
        val data = value(arguments, ChannelContract.DATA)
        require(data.isNotBlank()) { "Contextual data must not be empty" }
        return data
    }

    private fun value(arguments: Any?, key: String): String {
        val values = arguments as? Map<*, *> ?: throw IllegalArgumentException("Arguments are invalid")
        return values[key] as? String ?: throw IllegalArgumentException("Argument is invalid")
    }
}
