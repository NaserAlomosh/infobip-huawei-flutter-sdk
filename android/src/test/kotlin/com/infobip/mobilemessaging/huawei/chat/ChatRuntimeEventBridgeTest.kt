package com.infobip.mobilemessaging.huawei.chat

import org.junit.Assert.assertEquals
import org.junit.Test

class ChatRuntimeEventBridgeTest {
    @Test
    fun `replays buffered events in order`() {
        val emitted = mutableListOf<Map<String, String>>()
        val bridge = ChatRuntimeEventBridge(3, emitted::add)
        bridge.publish(mapOf("event" to "first"))
        bridge.publish(mapOf("event" to "second"))

        bridge.ready()

        assertEquals(listOf("first", "second"), emitted.map { it["event"] })
    }

    @Test
    fun `buffer is bounded to newest events`() {
        val emitted = mutableListOf<Map<String, String>>()
        val bridge = ChatRuntimeEventBridge(2, emitted::add)
        bridge.publish(mapOf("event" to "first"))
        bridge.publish(mapOf("event" to "second"))
        bridge.publish(mapOf("event" to "third"))

        bridge.ready()

        assertEquals(listOf("second", "third"), emitted.map { it["event"] })
    }

    @Test
    fun `dispose clears pending events and rejects future events`() {
        val emitted = mutableListOf<Map<String, String>>()
        val bridge = ChatRuntimeEventBridge(2, emitted::add)
        bridge.publish(mapOf("event" to "pending"))

        bridge.dispose()
        bridge.ready()
        bridge.publish(mapOf("event" to "late"))

        assertEquals(emptyList<Map<String, String>>(), emitted)
    }
}
