package com.infobip.mobilemessaging.huawei.chat

import java.util.ArrayDeque

internal interface ChatJwtCallback {
    fun onJwtReady(jwt: String)

    fun onJwtError(error: Throwable)
}

internal class ChatJwtBridge(
    private val requestDartJwt: () -> Boolean,
) {
    private val pendingCallbacks = ArrayDeque<ChatJwtCallback>()
    private var enabled = false
    private var requestInFlight = false

    @Synchronized
    fun enable() {
        enabled = true
    }

    @Synchronized
    fun request(callback: ChatJwtCallback) {
        if (!enabled) {
            callback.onJwtError(IllegalStateException(PROVIDER_UNAVAILABLE))
            return
        }
        pendingCallbacks.addLast(callback)
        requestNext()
    }

    @Synchronized
    fun resolve(jwt: Any?): Boolean {
        val value = (jwt as? String)?.trim()
        if (value.isNullOrEmpty()) return false
        val callback = pendingCallbacks.pollFirst() ?: return false
        requestInFlight = false
        callback.onJwtReady(value)
        requestNext()
        return true
    }

    @Synchronized
    fun reject(message: Any?): Boolean {
        val callback = pendingCallbacks.pollFirst() ?: return false
        requestInFlight = false
        val safeMessage = (message as? String)?.takeIf { it.isNotBlank() } ?: JWT_UNAVAILABLE
        callback.onJwtError(IllegalStateException(safeMessage))
        requestNext()
        return true
    }

    @Synchronized
    fun clear() {
        enabled = false
        requestInFlight = false
        while (pendingCallbacks.isNotEmpty()) {
            pendingCallbacks.removeFirst().onJwtError(IllegalStateException(PROVIDER_UNAVAILABLE))
        }
    }

    @Synchronized
    internal fun pendingCount(): Int = pendingCallbacks.size

    @Synchronized
    internal fun isRequestInFlight(): Boolean = requestInFlight

    private fun requestNext() {
        while (!requestInFlight && pendingCallbacks.isNotEmpty()) {
            requestInFlight = true
            if (requestDartJwt()) return
            requestInFlight = false
            pendingCallbacks.removeFirst().onJwtError(IllegalStateException(PROVIDER_UNAVAILABLE))
        }
    }

    private companion object {
        const val PROVIDER_UNAVAILABLE = "Chat JWT provider is unavailable"
        const val JWT_UNAVAILABLE = "Unable to provide Chat JWT"
    }
}
