package com.infobip.mobilemessaging.huawei.plugin

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PendingTapStoreTest {
    @Test
    fun `take replays a pending tap once`() {
        val store = PendingTapStore()
        val event = mapOf<String, Any?>("type" to "notification_tapped")
        store.save(event)

        assertEquals(event, store.take())
        assertNull(store.take())
    }

    @Test
    fun `latest tap replaces the previous pending tap`() {
        val store = PendingTapStore()
        store.save(mapOf("id" to "first"))
        store.save(mapOf("id" to "second"))

        assertEquals("second", store.take()?.get("id"))
    }

    @Test
    fun `clear removes a pending tap`() {
        val store = PendingTapStore()
        store.save(mapOf("id" to "tap"))
        store.clear()
        assertNull(store.take())
    }
}
