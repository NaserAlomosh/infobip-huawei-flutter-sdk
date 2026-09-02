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
            ChannelContract.CHAT_SEND -> handleSend(call, result, view)
            ChannelContract.CHAT_SEND_CONTEXTUAL_DATA -> handleContextualData(call, result, view)
            ChannelContract.CHAT_SET_LANGUAGE -> handleLanguage(call, result, view)
            ChannelContract.CHAT_GET_LANGUAGE -> readFromView(view, result) {
                ChatLanguageMapper.toWidgetCode(view.getLanguage())
            }
            ChannelContract.CHAT_SET_WIDGET_THEME -> handleStringArgument(
                call,
                result,
                view,
                ChannelContract.WIDGET_THEME,
            ) { view.setWidgetTheme(it) }
            ChannelContract.CHAT_GET_WIDGET_THEME -> readFromView(view, result) {
                view.getWidgetTheme()
            }
            else -> result.notImplemented()
        }
    }

    private fun handleLanguage(
        call: MethodCall,
        result: MethodChannel.Result,
        view: InAppChatView,
    ) {
        val languageCode = (call.arguments as? Map<*, *>)?.get(ChannelContract.LANGUAGE) as? String
        if (languageCode.isNullOrBlank()) {
            result.error("invalid_argument", "language must not be empty", null)
            return
        }
        val language = ChatLanguageMapper.fromWidgetCode(languageCode)
        if (language == null) {
            result.error("invalid_argument", "Unsupported Chat language", null)
            return
        }
        runOnView(view, result) { view.setLanguage(language) }
    }

    private fun handleStringArgument(
        call: MethodCall,
        result: MethodChannel.Result,
        view: InAppChatView,
        key: String,
        operation: (String) -> Unit,
    ) {
        val value = (call.arguments as? Map<*, *>)?.get(key) as? String
        if (value.isNullOrBlank()) {
            result.error("invalid_argument", "$key must not be empty", null)
            return
        }
        runOnView(view, result) { operation(value) }
    }

    private fun handleSend(call: MethodCall, result: MethodChannel.Result, view: InAppChatView) {
        val payload = try {
            ChatMapper.messagePayload(call.arguments)
        } catch (error: IllegalArgumentException) {
            result.error("invalid_argument", error.message, null)
            return
        }
        runOnView(view, result) { view.send(payload) }
    }

    private fun handleContextualData(
        call: MethodCall,
        result: MethodChannel.Result,
        view: InAppChatView,
    ) {
        val data = try {
            ChatMapper.contextualData(call.arguments)
        } catch (error: IllegalArgumentException) {
            result.error("invalid_argument", error.message, null)
            return
        }
        runOnView(view, result) { view.sendContextualData(data) }
    }

    private fun runOnView(
        view: InAppChatView,
        result: MethodChannel.Result,
        operation: () -> Unit,
    ) {
        view.post {
            if (chatView !== view) {
                result.error("chat_unavailable", "Chat view is unavailable", null)
                return@post
            }
            try {
                operation()
                result.success(null)
            } catch (_: RuntimeException) {
                result.error("native_error", "Chat operation failed", null)
            }
        }
    }

    private fun readFromView(
        view: InAppChatView,
        result: MethodChannel.Result,
        operation: () -> String,
    ) {
        view.post {
            if (chatView !== view) {
                result.error("chat_unavailable", "Chat view is unavailable", null)
                return@post
            }
            try {
                result.success(operation())
            } catch (_: RuntimeException) {
                result.error("native_error", "Chat operation failed", null)
            }
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
