package com.infobip.mobilemessaging.huawei.plugin

internal object ChannelContract {
    const val METHOD_CHANNEL = "com.infobip.mobilemessaging.huawei/methods"
    const val EVENT_CHANNEL = "com.infobip.mobilemessaging.huawei/events"
    const val INITIALIZE = "initialize"
    const val SET_REGISTRATION = "setRegistration"
    const val IS_REGISTRATION_ENABLED = "isRegistrationEnabled"
    const val APPLICATION_CODE = "applicationCode"
    const val ENABLED = "enabled"

    const val EVENT_VERSION = 1
    const val MESSAGE_RECEIVED = "message_received"
    const val NOTIFICATION_TAPPED = "notification_tapped"
    const val NOTIFICATION_ACTION_TAPPED = "notification_action_tapped"
    const val REGISTRATION_UPDATED = "registration_updated"
}
