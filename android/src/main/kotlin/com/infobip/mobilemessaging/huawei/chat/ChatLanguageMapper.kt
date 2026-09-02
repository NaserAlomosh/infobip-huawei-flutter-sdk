package com.infobip.mobilemessaging.huawei.chat

import org.infobip.mobile.messaging.chat.core.widget.LivechatWidgetLanguage

internal object ChatLanguageMapper {
    fun fromWidgetCode(widgetCode: String): LivechatWidgetLanguage? =
        LivechatWidgetLanguage.findLanguage(widgetCode)

    fun toWidgetCode(language: LivechatWidgetLanguage): String = language.widgetCode
}
