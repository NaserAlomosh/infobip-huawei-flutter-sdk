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
    private val initialized: () -> Boolean,
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
            initialized = initialized(),
        )
}
