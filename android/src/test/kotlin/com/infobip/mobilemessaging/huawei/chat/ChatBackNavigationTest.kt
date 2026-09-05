package com.infobip.mobilemessaging.huawei.chat

import org.infobip.mobile.messaging.chat.core.widget.LivechatWidgetView
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ChatBackNavigationTest {
    @Test
    fun `multithread thread view handles back internally`() {
        assertTrue(ChatBackNavigation.isHandledInternally(true, LivechatWidgetView.THREAD))
    }

    @Test
    fun `single thread chat delegates back`() {
        assertFalse(ChatBackNavigation.isHandledInternally(false, LivechatWidgetView.THREAD))
    }

    @Test
    fun `thread list delegates back`() {
        assertFalse(ChatBackNavigation.isHandledInternally(true, LivechatWidgetView.THREAD_LIST))
    }

    @Test
    fun `unknown view delegates back`() {
        assertFalse(ChatBackNavigation.isHandledInternally(true, null))
    }
}
