package com.infobip.mobilemessaging.huawei.chat

import org.infobip.mobile.messaging.chat.core.widget.LivechatWidgetLanguage
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class ChatLanguageMapperTest {
    @Test
    fun `maps supported widget codes to native languages`() {
        assertEquals(
            LivechatWidgetLanguage.ENGLISH,
            ChatLanguageMapper.fromWidgetCode("en-US"),
        )
        assertEquals(
            LivechatWidgetLanguage.ARABIC,
            ChatLanguageMapper.fromWidgetCode("ar-AE"),
        )
    }

    @Test
    fun `maps native languages to widget codes`() {
        assertEquals("en-US", ChatLanguageMapper.toWidgetCode(LivechatWidgetLanguage.ENGLISH))
        assertEquals("ar-AE", ChatLanguageMapper.toWidgetCode(LivechatWidgetLanguage.ARABIC))
    }

    @Test
    fun `rejects an unsupported widget code`() {
        assertNull(ChatLanguageMapper.fromWidgetCode("invalid-language"))
    }
}
