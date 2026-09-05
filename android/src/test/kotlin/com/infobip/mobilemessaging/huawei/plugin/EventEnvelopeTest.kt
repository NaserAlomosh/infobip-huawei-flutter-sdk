package com.infobip.mobilemessaging.huawei.plugin

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class EventEnvelopeTest {
    @Test
    fun `creates a versioned stable event envelope`() {
        val payload = mapOf<String, Any?>("message" to emptyMap<String, Any?>())
        val event = EventEnvelope.create(ChannelContract.MESSAGE_RECEIVED, payload)

        assertEquals(1, event["version"])
        assertEquals("message_received", event["type"])
        assertEquals(payload, event["payload"])
        assertTrue(event["timestamp"] is Long)
    }
}
