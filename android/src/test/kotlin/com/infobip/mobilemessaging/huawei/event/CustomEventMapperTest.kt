package com.infobip.mobilemessaging.huawei.event

import com.infobip.mobilemessaging.huawei.plugin.ChannelContract
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test
import java.util.Date

class CustomEventMapperTest {
    @Test
    fun `maps definition properties and tagged dates`() {
        val event =
            CustomEventMapper.fromMap(
                mapOf(
                    ChannelContract.DEFINITION_ID to " purchase ",
                    ChannelContract.PROPERTIES to
                        mapOf(
                            "amount" to 12.5,
                            "paid" to true,
                            "at" to
                                mapOf(
                                    ChannelContract.CUSTOM_VALUE_TYPE to ChannelContract.CUSTOM_DATE_TYPE,
                                    ChannelContract.CUSTOM_VALUE to "2026-09-05T12:00:00Z",
                                ),
                        ),
                ),
            )

        assertEquals("purchase", event.definitionId)
        assertEquals(12.5, event.properties?.get("amount"))
        assertEquals(true, event.properties?.get("paid"))
        assertEquals(Date.from(java.time.Instant.parse("2026-09-05T12:00:00Z")), event.properties?.get("at"))
    }

    @Test
    fun `rejects malformed payloads`() {
        assertThrows(IllegalArgumentException::class.java) {
            CustomEventMapper.fromMap(mapOf(ChannelContract.DEFINITION_ID to " "))
        }
        assertThrows(IllegalArgumentException::class.java) {
            CustomEventMapper.fromMap(
                mapOf(
                    ChannelContract.DEFINITION_ID to "event",
                    ChannelContract.PROPERTIES to mapOf("unsupported" to emptyMap<String, Any>()),
                ),
            )
        }
    }
}
