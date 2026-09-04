package com.infobip.mobilemessaging.huawei.core

import android.app.Application
import android.content.Context
import android.util.Log
import com.infobip.mobilemessaging.huawei.R
import org.infobip.mobile.messaging.MobileMessaging
import org.infobip.mobile.messaging.NotificationSettings
import org.infobip.mobile.messaging.mobileapi.InternalSdkError

internal class MobileMessagingInitializer(
    context: Context,
) {
    private val application = context.applicationContext as Application

    private val coordinator =
        InitializationCoordinator { applicationCode, complete ->
            try {
                Log.d(
                    TAG,
                    "Starting Infobip initialization. applicationCode length=${applicationCode.length}",
                )

                val notificationSettings =
                    NotificationSettings
                        .Builder(application)
                        .withDefaultIcon(R.drawable.ic_notification)
                        .build()

                MobileMessaging
                    .Builder(application)
                    .withApplicationCode(applicationCode)
                    .withDisplayNotification(notificationSettings)
                    .build(
                        object : MobileMessaging.InitListener {
                            override fun onSuccess() {
                                Log.d(TAG, "Infobip initialization success")
                                complete(null)
                            }

                            override fun onError(
                                error: InternalSdkError,
                                errorCode: Int?,
                            ) {
                                Log.e(
                                    TAG,
                                    "Infobip initialization failed. error=$error, errorCode=$errorCode",
                                )

                                complete(
                                    InitializationError(
                                        "initialization_failed",
                                        "Infobip SDK initialization failed: $error",
                                    ),
                                )
                            }
                        },
                    )
            } catch (e: Exception) {
                Log.e(
                    TAG,
                    "Exception while initializing Infobip SDK",
                    e,
                )

                complete(
                    InitializationError(
                        "native_error",
                        "Unable to initialize the Infobip SDK: ${e.message}",
                    ),
                )
            }
        }

    fun initialize(
        applicationCode: String,
        callback: (InitializationError?) -> Unit,
    ) {
        if (applicationCode.isBlank()) {
            callback(
                InitializationError(
                    "invalid_argument",
                    "applicationCode must not be empty",
                ),
            )
            return
        }

        coordinator.initialize(applicationCode, callback)
    }

    val isInitialized: Boolean
        get() = coordinator.isInitialized

    private companion object {
        const val TAG = "InfobipHuawei"
    }
}