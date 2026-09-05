package com.infobip.mobilemessaging.huawei.chat

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ChatViewErrorTest {
    @Test
    fun `creation errors use a stable envelope`() {
        assertEquals(mapOf("code" to "not_initialized"), ChatViewError("not_initialized").toMap())
        assertEquals(
            mapOf("code" to "activity_unavailable"),
            ChatViewError("activity_unavailable").toMap(),
        )
    }

    @Test
    fun `pending creation error is emitted once`() {
        val pending = PendingChatViewError()
        pending.set(ChatViewError("not_initialized"))

        assertEquals("not_initialized", pending.take()?.code)
        assertNull(pending.take())
    }
}
