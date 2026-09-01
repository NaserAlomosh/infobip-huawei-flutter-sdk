package com.infobip.mobilemessaging.huawei.plugin

internal class PendingTapStore {
    private var pending: Map<String, Any?>? = null

    @Synchronized
    fun save(event: Map<String, Any?>) {
        pending = event
    }

    @Synchronized
    fun take(): Map<String, Any?>? = pending.also { pending = null }

    @Synchronized
    fun clear() {
        pending = null
    }
}
