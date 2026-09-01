package com.infobip.mobilemessaging.huawei.chat

import android.app.Activity
import android.content.Context
import android.view.View
import android.widget.FrameLayout
import com.infobip.mobilemessaging.huawei.plugin.ChannelContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.infobip.mobile.messaging.chat.view.InAppChatView

internal class ChatPlatformView(
    context: Context,
    viewId: Int,
    messenger: BinaryMessenger,
    activity: Activity?,
    initialized: Boolean,
) : PlatformView, MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, ChannelContract.CHAT_VIEW_CHANNEL + viewId)
    private var chatView: InAppChatView? = null
    private val root: View
    private val pendingError = PendingChatViewError()

    init {
        root = when {
            !initialized -> neutralView(context, ChatViewError("not_initialized"))
            activity == null -> neutralView(context, ChatViewError("activity_unavailable"))
            else -> try {
                InAppChatView(activity).also { chatView = it }
            } catch (_: RuntimeException) {
                neutralView(context, ChatViewError("native_error", "Chat could not be created"))
            }
        }
        channel.setMethodCallHandler(this)
    }

    override fun getView(): View = root

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == ChannelContract.CHAT_VIEW_READY) {
            pendingError.take()?.let {
                channel.invokeMethod(ChannelContract.CHAT_ON_ERROR, it.toMap())
            }
            result.success(null)
            return
        }
        val view = chatView
        if (view == null) {
            result.error("chat_unavailable", "Chat view is unavailable", null)
            return
        }
        when (call.method) {
            ChannelContract.CHAT_NAVIGATE_BACK -> result.success(view.navigateBackOrCloseChat())
            else -> result.notImplemented()
        }
    }

    override fun dispose() {
        channel.setMethodCallHandler(null)
        chatView = null
    }

    private fun neutralView(context: Context, error: ChatViewError): View {
        pendingError.set(error)
        return FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
        }
    }
}
