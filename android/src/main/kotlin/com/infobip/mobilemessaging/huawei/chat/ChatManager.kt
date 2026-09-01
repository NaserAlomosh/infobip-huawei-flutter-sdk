package com.infobip.mobilemessaging.huawei.chat

import android.content.Context
import org.infobip.mobile.messaging.chat.InAppChatEventsListener
import org.infobip.mobile.messaging.chat.MobileChat

internal data class ChatFailure(val code: String, val message: String)

internal class ChatManager(
    context: Context,
    private val initialized: () -> Boolean,
    private val onUnreadMessageCountChanged: (Int) -> Unit,
) {
    private val applicationContext = context.applicationContext
    private var mobileChat: MobileChat? = null
    private var listenerRegistered = false
    private val eventsListener = object : InAppChatEventsListener {
        override fun onChangedUnreadMessagesCounter(unreadMessagesCounter: Int) {
            if (unreadMessagesCounter >= 0) onUnreadMessageCountChanged(unreadMessagesCounter)
        }
    }

    @Synchronized
    fun attach(): ChatFailure? {
        if (!initialized()) return ChatFailure("not_initialized", "Initialize the Infobip SDK first")
        if (listenerRegistered) return null
        return try {
            val chat = MobileChat.getInstance(applicationContext)
            chat.addInAppChatEventsListener(eventsListener)
            mobileChat = chat
            listenerRegistered = true
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
            val count = mobileChat?.unreadMessagesCounter
            if (count == null || count < 0) {
                callback(null, ChatFailure("native_error", "Unable to read Chat unread message count"))
            } else {
                callback(count, null)
            }
        } catch (_: Exception) {
            callback(null, ChatFailure("native_error", "Unable to read Chat unread message count"))
        }
    }

    @Synchronized
    fun detach() {
        if (listenerRegistered) {
            mobileChat?.removeInAppChatEventsListener(eventsListener)
        }
        listenerRegistered = false
        mobileChat = null
    }
}
