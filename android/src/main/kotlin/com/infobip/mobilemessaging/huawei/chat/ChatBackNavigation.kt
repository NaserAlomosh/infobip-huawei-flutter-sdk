package com.infobip.mobilemessaging.huawei.chat

import org.infobip.mobile.messaging.chat.core.widget.LivechatWidgetView

internal object ChatBackNavigation {
    fun isHandledInternally(
        isMultiThread: Boolean,
        currentWidgetView: LivechatWidgetView?,
    ): Boolean = isMultiThread && currentWidgetView == LivechatWidgetView.THREAD
}
