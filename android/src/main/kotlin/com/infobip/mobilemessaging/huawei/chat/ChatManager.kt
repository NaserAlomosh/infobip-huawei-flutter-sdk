package com.infobip.mobilemessaging.huawei.chat

import android.content.Context
import android.util.Log
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
    private val operations by lazy { ChatOperations.from(inAppChat) }
    @Volatile
    private var activated = false

    @Synchronized
    fun activate(): ChatFailure? {
        if (activated) return null
        Log.d(TAG, "InAppChat activation started")
        return try {
            inAppChat.activate()
            activated = true
            Log.d(TAG, "InAppChat activation succeeded")
            null
        } catch (error: Exception) {
            Log.e(TAG, "InAppChat activation failed", error)
            ChatFailure("chat_unavailable", "Chat activation failed")
        }
    }

    @Synchronized
    fun attach(): ChatFailure? {
        if (!initialized()) return ChatFailure("not_initialized", "Initialize the Infobip SDK first")
        if (!activated) return ChatFailure("chat_unavailable", "Chat is not activated")
        return null
    }

    fun instance(): InAppChat = inAppChat

    fun getUnreadMessageCount(callback: (Int?, ChatFailure?) -> Unit) {
        val failure = attach()
        if (failure != null) {
            callback(null, failure)
            return
        }
        try {
            val count = operations.getMessageCounter()
            if (count < 0) {
                callback(null, ChatFailure("native_error", "Unable to read Chat unread message count"))
            } else {
                callback(count, null)
            }
        } catch (_: Exception) {
            callback(null, ChatFailure("native_error", "Unable to read Chat unread message count"))
        }
    }

    fun isChatAvailable(callback: (Boolean?, ChatFailure?) -> Unit) = execute(
        "Unable to read Chat availability",
        callback,
    ) { operations.isChatAvailable() }

    fun resetMessageCounter(callback: (Unit?, ChatFailure?) -> Unit) = execute(
        "Unable to reset Chat message counter",
        callback,
    ) { operations.resetMessageCounter() }

    private fun <T> execute(
        failureMessage: String,
        callback: (T?, ChatFailure?) -> Unit,
        operation: () -> T,
    ) {
        val failure = attach()
        if (failure != null) {
            callback(null, failure)
            return
        }
        try {
            callback(operation(), null)
        } catch (_: Exception) {
            callback(null, ChatFailure("native_error", failureMessage))
        }
    }

    fun detach() = Unit

    private companion object {
        const val TAG = "InfobipHuaweiChat"
    }
}
