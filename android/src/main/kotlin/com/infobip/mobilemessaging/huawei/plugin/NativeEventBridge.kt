package com.infobip.mobilemessaging.huawei.plugin

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import org.infobip.mobile.messaging.Event
import org.infobip.mobile.messaging.EventBus
import org.infobip.mobile.messaging.Installation
import org.infobip.mobile.messaging.Message
import com.infobip.mobilemessaging.huawei.installation.InstallationMapper
import com.infobip.mobilemessaging.huawei.chat.ChatUnreadCount

internal class NativeEventBridge(
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
    private val pendingTapStore: PendingTapStore = PendingTapStore(),
) {
    private var sink: EventChannel.EventSink? = null
    private var registered = false

    private val messageReceivedListener = EventBus.EventListener<Message> { message ->
        emit(ChannelContract.MESSAGE_RECEIVED, mapOf("message" to MessageMapper.map(message)))
    }
    private val notificationTappedListener = EventBus.EventListener<Message> { message ->
        val event = EventEnvelope.create(
            ChannelContract.NOTIFICATION_TAPPED,
            mapOf("message" to MessageMapper.map(message)),
        )
        mainHandler.post {
            sink?.success(event) ?: pendingTapStore.save(event)
        }
    }
    private val actionTappedListener = EventBus.EventListener<Message> { message ->
        emit(
            ChannelContract.NOTIFICATION_ACTION_TAPPED,
            mapOf(
                "actionId" to message.action,
                "message" to MessageMapper.map(message),
            ),
        )
    }
    private val registrationUpdatedListener = EventBus.EventListener<Installation> { installation ->
        emit(
            ChannelContract.REGISTRATION_UPDATED,
            mapOf(ChannelContract.INSTALLATION to InstallationMapper.toMap(installation)),
        )
    }
    private val installationUpdatedListener = EventBus.EventListener<Installation> { installation ->
        emit(
            ChannelContract.INSTALLATION_UPDATED,
            mapOf(ChannelContract.INSTALLATION to InstallationMapper.toMap(installation)),
        )
    }

    @Synchronized
    fun register() {
        if (registered) return
        EventBus.getInstance().register(Event.MESSAGE_RECEIVED, messageReceivedListener)
        EventBus.getInstance().register(Event.NOTIFICATION_TAPPED, notificationTappedListener)
        EventBus.getInstance().register(Event.ACTION_TAPPED, actionTappedListener)
        EventBus.getInstance().register(Event.REGISTRATION_UPDATED, registrationUpdatedListener)
        EventBus.getInstance().register(Event.INSTALLATION_UPDATED, installationUpdatedListener)
        registered = true
    }

    fun listen(eventSink: EventChannel.EventSink?) {
        mainHandler.post {
            sink = eventSink
            pendingTapStore.take()?.let { eventSink?.success(it) }
        }
    }

    fun cancel() {
        mainHandler.post { sink = null }
    }

    @Synchronized
    fun detach() {
        if (registered) {
            EventBus.getInstance().unregister(Event.MESSAGE_RECEIVED, messageReceivedListener)
            EventBus.getInstance().unregister(Event.NOTIFICATION_TAPPED, notificationTappedListener)
            EventBus.getInstance().unregister(Event.ACTION_TAPPED, actionTappedListener)
            EventBus.getInstance().unregister(Event.REGISTRATION_UPDATED, registrationUpdatedListener)
            EventBus.getInstance().unregister(Event.INSTALLATION_UPDATED, installationUpdatedListener)
            registered = false
        }
        sink = null
        pendingTapStore.clear()
    }

    private fun emit(type: String, payload: Map<String, Any?>) {
        val event = EventEnvelope.create(type, payload)
        mainHandler.post { sink?.success(event) }
    }

    fun emitChatUnreadMessageCount(count: Int) {
        val payload = ChatUnreadCount.eventPayload(count) ?: return
        emit(
            ChannelContract.CHAT_UNREAD_MESSAGE_COUNTER_UPDATED,
            payload,
        )
    }
}
