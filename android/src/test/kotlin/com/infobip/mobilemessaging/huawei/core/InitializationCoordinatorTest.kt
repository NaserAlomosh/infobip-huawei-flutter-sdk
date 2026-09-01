package com.infobip.mobilemessaging.huawei.core

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class InitializationCoordinatorTest {
    @Test
    fun `first initialization starts native build`() {
        var starts = 0
        val coordinator = InitializationCoordinator { starts++ }
        coordinator.initialize("code") {}
        assertEquals(1, starts)
    }

    @Test
    fun `concurrent calls with same code share result`() {
        lateinit var complete: (InitializationError?) -> Unit
        var starts = 0
        val results = mutableListOf<InitializationError?>()
        val coordinator = InitializationCoordinator { starts++; complete = it }
        coordinator.initialize("code", results::add)
        coordinator.initialize("code", results::add)
        complete(null)
        assertEquals(1, starts)
        assertEquals(listOf(null, null), results)
    }

    @Test
    fun `repeated successful call does not rebuild`() {
        var starts = 0
        val coordinator = InitializationCoordinator { starts++; it(null) }
        var result: InitializationError? = InitializationError("test", "test")
        coordinator.initialize("code") { result = it }
        coordinator.initialize("code") { result = it }
        assertEquals(1, starts)
        assertNull(result)
    }

    @Test
    fun `different code is rejected after initialization starts`() {
        val coordinator = InitializationCoordinator {}
        var error: InitializationError? = null
        coordinator.initialize("first") {}
        coordinator.initialize("second") { error = it }
        assertEquals("already_initialized", error?.code)
    }

    @Test
    fun `failure is retained without another build`() {
        var starts = 0
        val expected = InitializationError("initialization_failed", "Failed")
        val coordinator = InitializationCoordinator { starts++; it(expected) }
        var error: InitializationError? = null
        coordinator.initialize("code") {}
        coordinator.initialize("code") { error = it }
        assertEquals(1, starts)
        assertEquals(expected, error)
    }
}
