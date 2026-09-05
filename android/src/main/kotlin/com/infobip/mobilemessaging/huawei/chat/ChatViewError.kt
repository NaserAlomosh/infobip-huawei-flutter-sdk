package com.infobip.mobilemessaging.huawei.chat

internal data class ChatViewError(
    val code: String,
    val message: String? = null,
) {
    fun toMap(): Map<String, Any> =
        buildMap {
            put("code", code)
            message?.let { put("message", it) }
        }
}

internal class PendingChatViewError {
    private var error: ChatViewError? = null
    private var delivered = false

    fun set(error: ChatViewError) {
        if (!delivered && this.error == null) this.error = error
    }

    fun take(): ChatViewError? {
        if (delivered) return null
        val current = error ?: return null
        delivered = true
        error = null
        return current
    }
}
