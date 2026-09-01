package com.infobip.mobilemessaging.huawei.core

import android.content.Context
import org.infobip.mobile.messaging.MobileMessaging

internal class MobileMessagingInitializer(context: Context) {
    private val applicationContext = context.applicationContext
    private val coordinator = InitializationCoordinator { applicationCode, complete ->
        try {
            MobileMessaging.Builder(applicationContext)
                .withApplicationCode(applicationCode)
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
        coordinator.initialize(applicationCode, callback)
    }

    val isInitialized: Boolean
        get() = coordinator.isInitialized
}
