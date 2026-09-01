package com.infobip.mobilemessaging.huawei

import com.infobip.mobilemessaging.huawei.core.InitializationError
import com.infobip.mobilemessaging.huawei.core.MobileMessagingInitializer
import com.infobip.mobilemessaging.huawei.plugin.ChannelContract
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class InfobipMobileMessagingHuaweiPlugin : FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var initializer: MobileMessagingInitializer? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        initializer = MobileMessagingInitializer(binding.applicationContext)
        methodChannel = MethodChannel(binding.binaryMessenger, ChannelContract.METHOD_CHANNEL).also {
            it.setMethodCallHandler(this)
        }
        eventChannel = EventChannel(binding.binaryMessenger, ChannelContract.EVENT_CHANNEL).also {
            it.setStreamHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        initializer = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            ChannelContract.INITIALIZE -> initialize(call, result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(call: MethodCall, result: MethodChannel.Result) {
        val applicationCode = call.argument<String>(ChannelContract.APPLICATION_CODE)
        if (applicationCode.isNullOrBlank()) {
            result.error("invalid_argument", "applicationCode must not be empty", null)
            return
        }

        initializer?.initialize(applicationCode) { error ->
            if (error == null) {
                result.success(null)
            } else {
                result.error(error.code, error.message, error.details)
            }
        } ?: result.error("native_error", "Plugin is not attached to an engine", null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) = Unit

    override fun onCancel(arguments: Any?) = Unit
}
