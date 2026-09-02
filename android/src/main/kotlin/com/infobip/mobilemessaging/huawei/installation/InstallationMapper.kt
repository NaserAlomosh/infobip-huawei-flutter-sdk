package com.infobip.mobilemessaging.huawei.installation

import com.infobip.mobilemessaging.huawei.plugin.ChannelContract
import com.infobip.mobilemessaging.huawei.user.UserMapper
import org.infobip.mobile.messaging.Installation

internal object InstallationMapper {
    fun toMap(value: Installation): Map<String, Any?> = mapOf(
        ChannelContract.INSTALLATION_ID to null,
        ChannelContract.PUSH_REGISTRATION_ID to value.pushRegistrationId,
        ChannelContract.PUSH_REGISTRATION_ENABLED to value.isPushRegistrationEnabled,
        ChannelContract.IS_PRIMARY_DEVICE to value.isPrimaryDevice,
        ChannelContract.NOTIFICATIONS_ENABLED to null,
        ChannelContract.DEVICE_MANUFACTURER to value.deviceManufacturer,
        ChannelContract.DEVICE_MODEL to value.deviceModel,
        ChannelContract.DEVICE_SECURE to null,
        ChannelContract.APPLICATION_VERSION to null,
        ChannelContract.OPERATING_SYSTEM to null,
        ChannelContract.OPERATING_SYSTEM_VERSION to null,
        ChannelContract.LANGUAGE to value.language,
        ChannelContract.DEVICE_TIMEZONE_ID to null,
        ChannelContract.SDK_VERSION to value.sdkVersion,
        ChannelContract.APP_USER_ID to null,
        ChannelContract.CUSTOM_ATTRIBUTES to UserMapper.channelValue(value.customAttributes),
    )

    fun applyWritable(target: Installation, payload: Any?): Installation {
        val map = payload as? Map<*, *>
            ?: throw IllegalArgumentException("installation must be a map")
        boolean(map, ChannelContract.IS_PRIMARY_DEVICE)?.let { target.isPrimaryDevice = it }
        if (map.containsKey(ChannelContract.CUSTOM_ATTRIBUTES)) {
            target.customAttributes = UserMapper.toNativeCustomAttributes(
                map[ChannelContract.CUSTOM_ATTRIBUTES],
            )
        }
        return target
    }

    private fun boolean(map: Map<*, *>, key: String): Boolean? {
        val value = map[key] ?: return null
        return value as? Boolean ?: throw IllegalArgumentException("$key must be a boolean")
    }
}
