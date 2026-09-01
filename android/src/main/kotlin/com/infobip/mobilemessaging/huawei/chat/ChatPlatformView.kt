package com.infobip.mobilemessaging.huawei.chat

import android.app.Activity
import android.content.Context
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
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

    init {
        root = when {
            !initialized -> errorView(context, "not_initialized")
            activity == null -> errorView(context, "activity_unavailable")
            else -> InAppChatView(activity).also { chatView = it }
        }
        channel.setMethodCallHandler(this)
    }

    override fun getView(): View = root

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
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

    private fun errorView(context: Context, code: String): View =
        TextView(context).apply {
            text = code
            contentDescription = code
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
        }
}
