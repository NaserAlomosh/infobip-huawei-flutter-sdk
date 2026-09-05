package com.infobip.mobilemessaging.huawei.chat

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ChatViewOptionsTest {
    @Test
    fun `defaults enable input and disable toolbar`() {
        val options = ChatViewOptions.from(null)
        assertTrue(options.withInput)
        assertFalse(options.withToolbar)
    }

    @Test
    fun `valid creation parameters are propagated`() {
        val options =
            ChatViewOptions.from(
                mapOf("withInput" to false, "withToolbar" to true),
            )
        assertFalse(options.withInput)
        assertTrue(options.withToolbar)
    }

    @Test
    fun `invalid creation parameters use defaults`() {
        val options =
            ChatViewOptions.from(
                mapOf("withInput" to "false", "withToolbar" to 1),
            )
        assertTrue(options.withInput)
        assertFalse(options.withToolbar)
    }
}
