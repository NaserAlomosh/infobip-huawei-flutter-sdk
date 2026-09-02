package com.infobip.mobilemessaging.huawei.chat

import android.content.Context
import org.infobip.mobile.messaging.chat.InAppChat

internal data class ChatFailure(
    val code: String,
    val message: String,
)

internal class ChatManager(
    context: Context,
    private val initialized: () -> Boolean,
) {
    private val applicationContext = context.applicationContext
    private val inAppChat by lazy { InAppChat.getInstance(applicationContext) }

    @Synchronized
    fun attach(): ChatFailure? {
        if (!initialized()) return ChatFailure("not_initialized", "Initialize the Infobip SDK first")
        return try {
            inAppChat
            null
        } catch (_: Exception) {
            ChatFailure("chat_unavailable", "Chat is unavailable")
        }
    }

    fun getUnreadMessageCount(callback: (Int?, ChatFailure?) -> Unit) {
        val failure = attach()
        if (failure != null) {
            callback(null, failure)
            return
        }
        try {
            val count = inAppChat.getMessageCounter()
            if (count < 0) {
                callback(null, ChatFailure("native_error", "Unable to read Chat unread message count"))
            } else {
                callback(count, null)
            }
        } catch (_: Exception) {
            callback(null, ChatFailure("native_error", "Unable to read Chat unread message count"))
        }
    }

    fun detach() = Unit
}
