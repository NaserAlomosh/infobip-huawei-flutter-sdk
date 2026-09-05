package com.infobip.mobilemessaging.huawei.chat

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ChatOperationsTest {
    @Test
    fun `availability delegates to native operation`() {
        var invoked = false
        val operations = ChatOperations(
            availability = {
                invoked = true
                true
            },
            messageCounter = { 0 },
            resetCounter = {},
        )

        assertTrue(operations.isChatAvailable())
        assertTrue(invoked)
    }

    @Test
    fun `availability preserves false`() {
        val operations = ChatOperations(
            availability = { false },
            messageCounter = { 0 },
            resetCounter = {},
        )

        assertFalse(operations.isChatAvailable())
    }

    @Test
    fun `reset delegates to native operation`() {
        var invoked = false
        val operations = ChatOperations(
            availability = { true },
            messageCounter = { 0 },
            resetCounter = { invoked = true },
        )

        operations.resetMessageCounter()

        assertTrue(invoked)
    }

    @Test
    fun `message counter delegates without duplicating state`() {
        var invoked = false
        val operations = ChatOperations(
            availability = { true },
            messageCounter = {
                invoked = true
                7
            },
            resetCounter = {},
        )

        assertTrue(operations.getMessageCounter() == 7)
        assertTrue(invoked)
    }
}
