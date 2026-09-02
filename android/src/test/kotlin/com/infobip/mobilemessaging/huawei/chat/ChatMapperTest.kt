package com.infobip.mobilemessaging.huawei.chat

import org.junit.Assert.assertEquals
import org.junit.Test
import org.infobip.mobile.messaging.chat.models.MessagePayload

class ChatMapperTest {
    @Test
    fun `maps a text payload against the native type`() {
        val payload = ChatMapper.messagePayload(mapOf("text" to "Hello"))

        assertEquals("Hello", (payload as MessagePayload.Basic).message)
    }

    @Test(expected = IllegalArgumentException::class)
    fun `rejects empty message text`() {
        ChatMapper.messagePayload(mapOf("text" to " "))
    }

    @Test
    fun `maps contextual data without inspecting its contents`() {
        val data = "{\"source\":\"support\"}"

        assertEquals(data, ChatMapper.contextualData(mapOf("data" to data)))
    }

    @Test(expected = IllegalArgumentException::class)
    fun `rejects malformed contextual data arguments`() {
        ChatMapper.contextualData(emptyMap<String, Any>())
    }
}
