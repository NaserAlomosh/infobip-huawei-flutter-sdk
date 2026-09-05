package com.infobip.mobilemessaging.huawei.chat

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class ChatPlatformViewFactory(
    private val messenger: BinaryMessenger,
    private val activityProvider: () -> Activity?,
    private val chatManager: ChatManager,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?,
    ): PlatformView =
        ChatPlatformView(
            context = context,
            viewId = viewId,
            messenger = messenger,
            activity = activityProvider(),
            chatManager = chatManager,
            options = ChatViewOptions.from(args),
        )
}

internal data class ChatViewOptions(
    val withInput: Boolean = true,
    val withToolbar: Boolean = false,
) {
    companion object {
        fun from(args: Any?): ChatViewOptions {
            val params = args as? Map<*, *> ?: return ChatViewOptions()
            return ChatViewOptions(
                withInput = params["withInput"] as? Boolean ?: true,
                withToolbar = params["withToolbar"] as? Boolean ?: false,
            )
        }
    }
}
