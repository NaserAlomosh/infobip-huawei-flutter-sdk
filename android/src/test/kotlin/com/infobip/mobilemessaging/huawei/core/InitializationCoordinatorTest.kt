package com.infobip.mobilemessaging.huawei.core

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class InitializationCoordinatorTest {
    @Test
    fun `first initialization starts native build once`() {
        var starts = 0
        val coordinator = InitializationCoordinator { code, _ ->
            starts++
            assertEquals("code", code)
        }

        coordinator.initialize("code") {}

        assertEquals(1, starts)
    }

    @Test
    fun `concurrent calls with same code share native build and result`() {
        lateinit var complete: (InitializationError?) -> Unit
        var starts = 0
        val results = mutableListOf<InitializationError?>()
        val coordinator = InitializationCoordinator { _, completion ->
            starts++
            complete = completion
        }

        coordinator.initialize("code", results::add)
        coordinator.initialize("code", results::add)
        complete(null)

        assertEquals(1, starts)
        assertEquals(listOf(null, null), results)
    }

    @Test
    fun `repeated same-code call after success does not rebuild`() {
        var starts = 0
        val coordinator = InitializationCoordinator { _, complete ->
            starts++
            complete(null)
        }
        var result: InitializationError? = InitializationError("test", "test")

        coordinator.initialize("code") { result = it }
        coordinator.initialize("code") { result = it }

        assertEquals(1, starts)
        assertNull(result)
    }

    @Test
    fun `different code while initializing is rejected`() {
        val coordinator = InitializationCoordinator { _, _ -> }
        var error: InitializationError? = null

        coordinator.initialize("first") {}
        coordinator.initialize("second") { error = it }

        assertEquals("already_initialized", error?.code)
    }

    @Test
    fun `different code after success is rejected`() {
        val coordinator = InitializationCoordinator { _, complete -> complete(null) }
        var error: InitializationError? = null

        coordinator.initialize("first") {}
        coordinator.initialize("second") { error = it }

        assertEquals("already_initialized", error?.code)
    }

    @Test
    fun `failure completes all waiting callbacks`() {
        lateinit var complete: (InitializationError?) -> Unit
        val expected = InitializationError("initialization_failed", "Failed")
        val results = mutableListOf<InitializationError?>()
        val coordinator = InitializationCoordinator { _, completion -> complete = completion }
        coordinator.initialize("code", results::add)
        coordinator.initialize("code", results::add)

        complete(expected)

        assertEquals(listOf(expected, expected), results)
    }

    @Test
    fun `same-code call after failure starts a new native build`() {
        val completions = mutableListOf<(InitializationError?) -> Unit>()
        val coordinator = InitializationCoordinator { _, complete -> completions += complete }
        coordinator.initialize("code") {}
        completions.single()(InitializationError("initialization_failed", "Failed"))

        coordinator.initialize("code") {}

        assertEquals(2, completions.size)
    }

    @Test
    fun `retry succeeds after previous failure`() {
        val completions = mutableListOf<(InitializationError?) -> Unit>()
        val results = mutableListOf<InitializationError?>()
        val coordinator = InitializationCoordinator { _, complete -> completions += complete }
        val failure = InitializationError("native_error", "Failed")
        coordinator.initialize("code", results::add)
        completions[0](failure)

        coordinator.initialize("code", results::add)
        completions[1](null)
        coordinator.initialize("code", results::add)

        assertEquals(2, completions.size)
        assertEquals(listOf(failure, null, null), results)
    }

    @Test
    fun `different code after failure is rejected`() {
        lateinit var complete: (InitializationError?) -> Unit
        var starts = 0
        val coordinator = InitializationCoordinator { _, completion ->
            starts++
            complete = completion
        }
        coordinator.initialize("first") {}
        complete(InitializationError("initialization_failed", "Failed"))
        var error: InitializationError? = null

        coordinator.initialize("second") { error = it }

        assertEquals(1, starts)
        assertEquals("already_initialized", error?.code)
    }

    @Test
    fun `callbacks run after state mutation and outside coordinator monitor`() {
        lateinit var complete: (InitializationError?) -> Unit
        var starts = 0
        val coordinator = InitializationCoordinator { _, completion ->
            starts++
            complete = completion
        }
        coordinator.initialize("code") {
            assertMonitorAvailable(coordinator)
            coordinator.initialize("code") { repeatedError -> assertNull(repeatedError) }
        }

        complete(null)

        assertEquals(1, starts)
    }

    @Test
    fun `completion clears pending callbacks`() {
        val completions = mutableListOf<(InitializationError?) -> Unit>()
        var callbackCount = 0
        val coordinator = InitializationCoordinator { _, completion -> completions += completion }
        coordinator.initialize("code") { callbackCount++ }

        completions[0](InitializationError("initialization_failed", "Failed"))
        coordinator.initialize("code") { callbackCount++ }
        completions[0](null)

        assertEquals(1, callbackCount)

        completions[1](null)

        assertEquals(2, callbackCount)
    }

    private fun assertMonitorAvailable(coordinator: InitializationCoordinator) {
        val acquired = CountDownLatch(1)
        val thread = Thread {
            synchronized(coordinator) {
                acquired.countDown()
            }
        }
        thread.start()
        assertTrue(acquired.await(1, TimeUnit.SECONDS))
        thread.join()
    }
}
