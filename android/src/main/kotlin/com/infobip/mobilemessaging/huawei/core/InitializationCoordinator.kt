package com.infobip.mobilemessaging.huawei.core

internal data class InitializationError(
    val code: String,
    val message: String,
    val details: Map<String, Any?>? = null,
)

internal class InitializationCoordinator(
    private val start: ((InitializationError?) -> Unit) -> Unit,
) {
    internal enum class State { NOT_INITIALIZED, INITIALIZING, INITIALIZED, FAILED }

    private var state = State.NOT_INITIALIZED
    private var applicationCode: String? = null
    private var failure: InitializationError? = null
    private val callbacks = mutableListOf<(InitializationError?) -> Unit>()

    fun initialize(code: String, callback: (InitializationError?) -> Unit) {
        var shouldStart = false
        synchronized(this) {
            if (applicationCode != null && applicationCode != code) {
                callback(InitializationError("already_initialized", "Initialization already started with a different application code"))
                return
            }
            when (state) {
                State.INITIALIZED -> callback(null)
                State.FAILED -> callback(failure)
                State.INITIALIZING -> callbacks += callback
                State.NOT_INITIALIZED -> {
                    applicationCode = code
                    state = State.INITIALIZING
                    callbacks += callback
                    shouldStart = true
                }
            }
        }
        if (shouldStart) start(::complete)
    }

    private fun complete(error: InitializationError?) {
        val pending: List<(InitializationError?) -> Unit>
        synchronized(this) {
            if (state != State.INITIALIZING) return
            failure = error
            state = if (error == null) State.INITIALIZED else State.FAILED
            pending = callbacks.toList()
            callbacks.clear()
        }
        pending.forEach { it(error) }
    }
}
