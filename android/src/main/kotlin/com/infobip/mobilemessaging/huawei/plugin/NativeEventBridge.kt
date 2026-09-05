package com.infobip.mobilemessaging.huawei.plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import androidx.localbroadcastmanager.content.LocalBroadcastManager
import com.infobip.mobilemessaging.huawei.installation.InstallationMapper
import com.infobip.mobilemessaging.huawei.user.UserMapper
import io.flutter.plugin.common.EventChannel
import org.infobip.mobile.messaging.Event
import org.infobip.mobile.messaging.Installation
import org.infobip.mobile.messaging.Message
import org.infobip.mobile.messaging.User

internal class NativeEventBridge(
    context: Context,
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
) {
    private val broadcasts = LocalBroadcastManager.getInstance(context.applicationContext)
    private var sink: EventChannel.EventSink? = null
    private var registered = false

    private val receiver =
        object : BroadcastReceiver() {
            override fun onReceive(
                context: Context?,
                intent: Intent?,
            ) {
                when (intent?.action) {
                    Event.MESSAGE_RECEIVED.key -> {
                        intent.extraOfType<Message>()?.let { message ->
                            emit(ChannelContract.MESSAGE_RECEIVED, mapOf("message" to MessageMapper.map(message)))
                        }
                    }

                    Event.INSTALLATION_UPDATED.key -> {
                        intent.extraOfType<Installation>()?.let { installation ->
                            emit(
                                ChannelContract.INSTALLATION_UPDATED,
                                mapOf(ChannelContract.INSTALLATION to InstallationMapper.toMap(installation)),
                            )
                        }
                    }

                    Event.USER_UPDATED.key -> emitUser(intent, ChannelContract.USER_UPDATED)

                    Event.PERSONALIZED.key -> emitUser(intent, ChannelContract.PERSONALIZED)

                    Event.DEPERSONALIZED.key -> emit(ChannelContract.DEPERSONALIZED, emptyMap())
                }
            }
        }

    @Synchronized
    fun register() {
        if (registered) return
        broadcasts.registerReceiver(
            receiver,
            IntentFilter().apply {
                addAction(Event.MESSAGE_RECEIVED.key)
                addAction(Event.INSTALLATION_UPDATED.key)
                addAction(Event.USER_UPDATED.key)
                addAction(Event.PERSONALIZED.key)
                addAction(Event.DEPERSONALIZED.key)
            },
        )
        registered = true
    }

    fun listen(eventSink: EventChannel.EventSink?) {
        mainHandler.post { sink = eventSink }
    }

    fun cancel() {
        mainHandler.post { sink = null }
    }

    @Synchronized
    fun detach() {
        if (registered) {
            broadcasts.unregisterReceiver(receiver)
            registered = false
        }
        sink = null
    }

    private fun emit(
        type: String,
        payload: Map<String, Any?>,
    ) {
        val event = EventEnvelope.create(type, payload)
        mainHandler.post { sink?.success(event) }
    }

    private fun emitUser(
        intent: Intent,
        type: String,
    ) {
        intent.extraOfType<User>()?.let { user ->
            emit(type, mapOf(ChannelContract.USER to UserMapper.toMap(user)))
        }
    }

    private inline fun <reified T> Intent.extraOfType(): T? {
        val extras = extras ?: return null
        return extras
            .keySet()
            .asSequence()
            .mapNotNull { extras.get(it) as? T }
            .firstOrNull()
    }
}
