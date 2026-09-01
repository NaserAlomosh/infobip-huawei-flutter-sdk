package com.infobip.mobilemessaging.huawei.plugin

internal object EventEnvelope {
    fun create(type: String, payload: Map<String, Any?>): Map<String, Any?> = mapOf(
        "version" to ChannelContract.EVENT_VERSION,
        "type" to type,
        "timestamp" to System.currentTimeMillis(),
        "payload" to payload,
    )
}
