package com.infobip.mobilemessaging.huawei.core

import android.content.Context
import org.infobip.mobile.messaging.MobileMessaging

internal class MobileMessagingInitializer(context: Context) {
    private val applicationContext = context.applicationContext
    private var codeForBuild: String? = null
    private val coordinator = InitializationCoordinator { complete ->
        val code = requireNotNull(codeForBuild)
        try {
            MobileMessaging.Builder(applicationContext)
                .withApplicationCode(code)
                .build { result ->
                    if (result.isSuccess) {
                        complete(null)
                    } else {
                        complete(
                            InitializationError(
                                "initialization_failed",
                                "Infobip SDK initialization failed",
                            ),
                        )
                    }
                }
        } catch (_: Exception) {
            complete(InitializationError("native_error", "Unable to initialize the Infobip SDK"))
        }
    }

    fun initialize(applicationCode: String, callback: (InitializationError?) -> Unit) {
        if (applicationCode.isBlank()) {
            callback(InitializationError("invalid_argument", "applicationCode must not be empty"))
            return
        }
        synchronized(this) {
            if (codeForBuild == null) codeForBuild = applicationCode
        }
        coordinator.initialize(applicationCode, callback)
    }
}
