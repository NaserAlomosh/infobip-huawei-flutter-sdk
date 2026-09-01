package com.infobip.mobilemessaging.huawei.inbox

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Test

class InboxMapperTest {
    @Test
    fun `parses UTC filters`() {
        val options = InboxMapper.parseOptions(
            mapOf(
                "from" to "2026-09-01T12:00:00Z",
                "to" to "2026-09-02T12:00:00Z",
                "topic" to "news",
                "limit" to 25,
            ),
        )

        assertEquals("2026-09-01T12:00:00Z", options.from?.toInstant().toString())
        assertEquals("news", options.topic)
        assertEquals(25, options.limit)
    }

    @Test
    fun `keeps omitted filters absent`() {
        val options = InboxMapper.parseOptions(null)
        assertNull(options.from)
        assertNull(options.to)
        assertNull(options.topic)
        assertNull(options.limit)
    }

    @Test
    fun `rejects invalid ranges and limits`() {
        assertThrows(IllegalArgumentException::class.java) {
            InboxMapper.parseOptions(
                mapOf("from" to "2026-09-02T00:00:00Z", "to" to "2026-09-01T00:00:00Z"),
            )
        }
        assertThrows(IllegalArgumentException::class.java) {
            InboxMapper.parseOptions(mapOf("limit" to 0))
        }
    }

    @Test
    fun `validates seen identifiers`() {
        assertEquals(listOf("one", "two"), InboxMapper.messageIds(listOf("one", "two")))
        assertThrows(IllegalArgumentException::class.java) { InboxMapper.messageIds(emptyList<String>()) }
        assertThrows(IllegalArgumentException::class.java) { InboxMapper.messageIds(listOf("")) }
    }
}
