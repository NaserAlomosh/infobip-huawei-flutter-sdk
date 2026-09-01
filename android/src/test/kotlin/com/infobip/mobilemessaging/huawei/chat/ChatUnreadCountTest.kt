package com.infobip.mobilemessaging.huawei.chat

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ChatUnreadCountTest {
    @Test
    fun `maps zero and positive counts`() {
        assertEquals(mapOf("count" to 0), ChatUnreadCount.eventPayload(0))
        assertEquals(mapOf("count" to 5), ChatUnreadCount.eventPayload(5))
    }

    @Test
    fun `rejects negative counts`() {
        assertNull(ChatUnreadCount.eventPayload(-1))
    }
}
