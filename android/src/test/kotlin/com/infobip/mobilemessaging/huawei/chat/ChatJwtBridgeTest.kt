package com.infobip.mobilemessaging.huawei.chat

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ChatJwtBridgeTest {
    @Test
    fun `request without enabled provider fails safely`() {
        val callback = RecordingCallback()
        val bridge = ChatJwtBridge { true }

        bridge.request(callback)

        assertEquals(1, callback.errors.size)
        assertEquals(0, bridge.pendingCount())
    }

    @Test
    fun `queues callbacks while only one Dart request is active`() {
        var requests = 0
        val bridge = ChatJwtBridge { requests++; true }.also { it.enable() }

        bridge.request(RecordingCallback())
        bridge.request(RecordingCallback())

        assertEquals(1, requests)
        assertEquals(2, bridge.pendingCount())
        assertTrue(bridge.isRequestInFlight())
    }

    @Test
    fun `each resolution completes one callback and requests another JWT`() {
        var requests = 0
        val first = RecordingCallback()
        val second = RecordingCallback()
        val bridge = ChatJwtBridge { requests++; true }.also { it.enable() }
        bridge.request(first)
        bridge.request(second)

        assertTrue(bridge.resolve("token-1"))
        assertEquals(listOf("token-1"), first.tokens)
        assertTrue(second.tokens.isEmpty())
        assertEquals(2, requests)
        assertEquals(1, bridge.pendingCount())

        assertTrue(bridge.resolve("token-2"))
        assertEquals(listOf("token-2"), second.tokens)
        assertEquals(0, bridge.pendingCount())
        assertFalse(bridge.isRequestInFlight())
    }

    @Test
    fun `rejection completes one callback with an error`() {
        val callback = RecordingCallback()
        val bridge = ChatJwtBridge { true }.also { it.enable() }
        bridge.request(callback)

        assertTrue(bridge.reject("JWT generation failed"))

        assertEquals(1, callback.errors.size)
        assertEquals(0, bridge.pendingCount())
    }

    @Test
    fun `invalid or unmatched responses are rejected`() {
        val callback = RecordingCallback()
        val bridge = ChatJwtBridge { true }.also { it.enable() }
        bridge.request(callback)

        assertFalse(bridge.resolve("  "))
        assertEquals(1, bridge.pendingCount())
        assertTrue(bridge.reject(null))
        assertFalse(bridge.resolve("token"))
    }

    @Test
    fun `clear fails all callbacks and resets bridge`() {
        val first = RecordingCallback()
        val second = RecordingCallback()
        val bridge = ChatJwtBridge { true }.also { it.enable() }
        bridge.request(first)
        bridge.request(second)

        bridge.clear()

        assertEquals(1, first.errors.size)
        assertEquals(1, second.errors.size)
        assertEquals(0, bridge.pendingCount())
        assertFalse(bridge.isRequestInFlight())
    }

    private class RecordingCallback : ChatJwtCallback {
        val tokens = mutableListOf<String>()
        val errors = mutableListOf<Throwable>()

        override fun onJwtReady(jwt: String) {
            tokens += jwt
        }

        override fun onJwtError(error: Throwable) {
            errors += error
        }
    }
}
