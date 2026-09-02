package com.infobip.mobilemessaging.huawei.core

import android.app.Application
import android.content.Context
import org.infobip.mobile.messaging.MobileMessaging
import org.infobip.mobile.messaging.mobileapi.InternalSdkError

internal class MobileMessagingInitializer(context: Context) {
    private val application = context.applicationContext as Application
    private val coordinator = InitializationCoordinator { applicationCode, complete ->
        try {
            MobileMessaging.Builder(application)
                .withApplicationCode(applicationCode)
                .build(object : MobileMessaging.InitListener {
                    override fun onSuccess() {
                        complete(null)
                    }

                    override fun onError(error: InternalSdkError, errorCode: Int?) {
                        complete(
                            InitializationError(
                                "initialization_failed",
                                "Infobip SDK initialization failed",
                            ),
                        )
                    }
                })
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
