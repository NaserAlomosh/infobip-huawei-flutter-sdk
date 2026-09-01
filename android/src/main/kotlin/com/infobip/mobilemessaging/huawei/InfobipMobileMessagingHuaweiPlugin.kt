package com.infobip.mobilemessaging.huawei

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.infobip.mobilemessaging.huawei.core.MobileMessagingInitializer
import com.infobip.mobilemessaging.huawei.plugin.ChannelContract
import com.infobip.mobilemessaging.huawei.plugin.NativeEventBridge
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.infobip.mobile.messaging.MobileMessaging

class InfobipMobileMessagingHuaweiPlugin : FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var initializer: MobileMessagingInitializer? = null
    private var applicationContext: Context? = null
    private var eventBridge: NativeEventBridge? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        initializer = MobileMessagingInitializer(binding.applicationContext)
        eventBridge = NativeEventBridge().also { it.register() }
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
        eventBridge?.detach()
        methodChannel = null
        eventChannel = null
        initializer = null
        eventBridge = null
        applicationContext = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            ChannelContract.INITIALIZE -> initialize(call, result)
            ChannelContract.SET_REGISTRATION -> setRegistration(call, result)
            ChannelContract.IS_REGISTRATION_ENABLED -> isRegistrationEnabled(result)
            else -> result.notImplemented()
        }
    }

    private fun setRegistration(call: MethodCall, result: MethodChannel.Result) {
        if (initializer?.isInitialized != true) {
            result.error("not_initialized", "Initialize the Infobip SDK first", null)
            return
        }
        val enabled = call.argument<Boolean>(ChannelContract.ENABLED)
        if (enabled == null) {
            result.error("invalid_argument", "enabled must be a boolean", null)
            return
        }
        val context = applicationContext ?: run {
            result.error("native_error", "Plugin is not attached to an engine", null)
            return
        }
        try {
            MobileMessaging.getInstance(context).setRegistration(enabled) { sdkResult ->
                mainHandler.post {
                    if (sdkResult.isSuccess) {
                        result.success(null)
                    } else {
                        result.error("registration_failed", "Push registration update failed", null)
                    }
                }
            }
        } catch (_: Exception) {
            result.error("native_error", "Unable to update push registration", null)
        }
    }

    private fun isRegistrationEnabled(result: MethodChannel.Result) {
        if (initializer?.isInitialized != true) {
            result.error("not_initialized", "Initialize the Infobip SDK first", null)
            return
        }
        val context = applicationContext ?: run {
            result.error("native_error", "Plugin is not attached to an engine", null)
            return
        }
        try {
            result.success(
                MobileMessaging.getInstance(context).installation.isPushRegistrationEnabled,
            )
        } catch (_: Exception) {
            result.error("native_error", "Unable to read push registration state", null)
        }
    }

    private fun initialize(call: MethodCall, result: MethodChannel.Result) {
        val applicationCode = call.argument<String>(ChannelContract.APPLICATION_CODE)
        if (applicationCode.isNullOrBlank()) {
            result.error("invalid_argument", "applicationCode must not be empty", null)
            return
        }

        initializer?.initialize(applicationCode) { error ->
            mainHandler.post {
                if (error == null) {
                    result.success(null)
                } else {
                    result.error(error.code, error.message, error.details)
                }
            }
        } ?: result.error("native_error", "Plugin is not attached to an engine", null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventBridge?.listen(events)
    }

    override fun onCancel(arguments: Any?) {
        eventBridge?.cancel()
    }
}
