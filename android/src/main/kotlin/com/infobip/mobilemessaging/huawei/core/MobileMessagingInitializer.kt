package com.infobip.mobilemessaging.huawei.core

import android.app.Application
import android.content.Context
import android.util.Log
import com.infobip.mobilemessaging.huawei.R
import org.infobip.mobile.messaging.MobileMessaging
import org.infobip.mobile.messaging.NotificationSettings
import org.infobip.mobile.messaging.chat.InAppChat
import org.infobip.mobile.messaging.mobileapi.InternalSdkError
import org.infobip.mobile.messaging.storage.SQLiteMessageStore

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
                        .withMultipleNotifications()
                        .withDefaultIcon(R.drawable.ic_notification)
                        .build()

                MobileMessaging
                    .Builder(application)
                    .withApplicationCode(applicationCode)
                    .withMessageStore(SQLiteMessageStore::class.java)
                    .withFullFeaturedInApps()
                    .withDisplayNotification(notificationSettings)
                    .build(
                        object : MobileMessaging.InitListener {
                            override fun onSuccess() {
                                Log.d(TAG, "Infobip initialization success")
                                try {
                                    InAppChat.getInstance(application).activate()
                                } catch (e: Exception) {
                                    Log.e(TAG, "Unable to activate Infobip In-app Chat", e)
                                }
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

    fun registerForRemoteNotifications(callback: (InitializationError?) -> Unit) {
        if (!isInitialized) {
            callback(
                InitializationError(
                    "not_initialized",
                    "Initialize the Infobip SDK first",
                ),
            )
            return
        }
        try {
            MobileMessaging.getInstance(application).registerForRemoteNotifications()
            callback(null)
        } catch (e: Exception) {
            Log.e(TAG, "Unable to register for remote notifications", e)
            callback(
                InitializationError(
                    "registration_failed",
                    e.message ?: "Unable to register for remote notifications",
                ),
            )
        }
    }

    private companion object {
        const val TAG = "InfobipHuawei"
    }
}
