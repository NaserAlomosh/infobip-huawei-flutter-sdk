package com.infobip.mobilemessaging.huawei.installation

import com.infobip.mobilemessaging.huawei.plugin.ChannelContract
import org.infobip.mobile.messaging.Installation
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.Instant
import java.util.Date

class InstallationMapperTest {
    @Test
    fun `maps native installation fields`() {
        val installation = Installation().apply {
            isPushRegistrationEnabled = true
            isPrimaryDevice = false
            language = "en"
            customAttributes = mapOf("created" to Date.from(Instant.parse("2026-09-01T10:15:30Z")))
        }

        val mapped = InstallationMapper.toMap(installation)

        assertEquals(true, mapped[ChannelContract.PUSH_REGISTRATION_ENABLED])
        assertEquals(false, mapped[ChannelContract.IS_PRIMARY_DEVICE])
        assertEquals("en", mapped[ChannelContract.LANGUAGE])
        val attributes = mapped[ChannelContract.CUSTOM_ATTRIBUTES] as Map<*, *>
        assertEquals(
            ChannelContract.CUSTOM_DATE_TYPE,
            (attributes["created"] as Map<*, *>)[ChannelContract.CUSTOM_VALUE_TYPE],
        )
    }

    @Test
    fun `applies only writable fields`() {
        val installation = Installation()
        InstallationMapper.applyWritable(
            installation,
            mapOf(
                ChannelContract.PUSH_REGISTRATION_ID to "ignored",
                ChannelContract.DEVICE_MODEL to "ignored",
                ChannelContract.LANGUAGE to "ignored",
                ChannelContract.CUSTOM_ATTRIBUTES to mapOf("score" to 3),
            ),
        )

        assertNull(installation.pushRegistrationId)
        assertNull(installation.deviceModel)
        assertNull(installation.language)
        assertEquals(3, installation.customAttributes["score"])
    }
}
