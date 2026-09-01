package com.infobip.mobilemessaging.huawei.chat

internal object ChatUnreadCount {
    fun eventPayload(count: Int): Map<String, Any>? =
        if (count >= 0) mapOf("count" to count) else null
}
