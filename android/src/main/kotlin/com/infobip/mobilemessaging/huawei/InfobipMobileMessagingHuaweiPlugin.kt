package com.infobip.mobilemessaging.huawei

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.infobip.mobilemessaging.huawei.core.MobileMessagingInitializer
import com.infobip.mobilemessaging.huawei.plugin.ChannelContract
import com.infobip.mobilemessaging.huawei.plugin.NativeEventBridge
import com.infobip.mobilemessaging.huawei.user.UserManager
import com.infobip.mobilemessaging.huawei.installation.InstallationManager
import com.infobip.mobilemessaging.huawei.inbox.InboxManager
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
    private var userManager: UserManager? = null
    private var installationManager: InstallationManager? = null
    private var inboxManager: InboxManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        initializer = MobileMessagingInitializer(binding.applicationContext)
        userManager = UserManager(binding.applicationContext) {
            initializer?.isInitialized == true
        }
        installationManager = InstallationManager(binding.applicationContext) {
            initializer?.isInitialized == true
        }
        inboxManager = InboxManager(binding.applicationContext) {
            initializer?.isInitialized == true
        }
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
        userManager = null
        installationManager = null
        inboxManager = null
        applicationContext = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            ChannelContract.INITIALIZE -> initialize(call, result)
            ChannelContract.SET_REGISTRATION -> setRegistration(call, result)
            ChannelContract.IS_REGISTRATION_ENABLED -> isRegistrationEnabled(result)
            ChannelContract.GET_USER -> userManager?.getUser(result::completeUser)
                ?: detached(result)
            ChannelContract.FETCH_USER -> userManager?.fetchUser(result::completeUser)
                ?: detached(result)
            ChannelContract.SAVE_USER -> userManager?.saveUser(
                call.argument<Any?>(ChannelContract.USER),
                result::completeUser,
            ) ?: detached(result)
            ChannelContract.PERSONALIZE -> personalize(call, result)
            ChannelContract.DEPERSONALIZE -> userManager?.depersonalize { _, failure ->
                if (failure == null) result.success(null)
                else result.error(failure.code, failure.message, null)
            } ?: detached(result)
            ChannelContract.GET_INSTALLATION -> installationManager?.getInstallation(result::completeInstallation)
                ?: detached(result)
            ChannelContract.FETCH_INSTALLATION -> installationManager?.fetchInstallation(result::completeInstallation)
                ?: detached(result)
            ChannelContract.SAVE_INSTALLATION -> installationManager?.saveInstallation(
                call.argument<Any?>(ChannelContract.INSTALLATION),
                result::completeInstallation,
            ) ?: detached(result)
            ChannelContract.FETCH_INBOX -> inboxManager?.fetch(
                call.argument<Any?>(ChannelContract.EXTERNAL_USER_ID),
                call.argument<Any?>(ChannelContract.JWT),
                call.argument<Any?>(ChannelContract.OPTIONS),
                result::completeInbox,
            ) ?: detached(result)
            ChannelContract.SET_INBOX_MESSAGES_SEEN -> inboxManager?.setSeen(
                call.argument<Any?>(ChannelContract.EXTERNAL_USER_ID),
                call.argument<Any?>(ChannelContract.MESSAGE_IDS),
                result::completeInbox,
            ) ?: detached(result)
            else -> result.notImplemented()
        }
    }

    private fun personalize(call: MethodCall, result: MethodChannel.Result) {
        val force = call.argument<Boolean>(ChannelContract.FORCE_DEPERSONALIZE)
        if (force == null) {
            result.error("invalid_argument", "forceDepersonalize must be a boolean", null)
            return
        }
        userManager?.personalize(
            call.argument<Any?>(ChannelContract.USER_IDENTITY),
            call.argument<Any?>(ChannelContract.USER_ATTRIBUTES),
            force,
            result::completeUser,
        ) ?: detached(result)
    }

    private fun MethodChannel.Result.completeUser(
        user: Map<String, Any?>?,
        failure: com.infobip.mobilemessaging.huawei.user.UserFailure?,
    ) {
        if (failure == null) success(user)
        else error(failure.code, failure.message, null)
    }

    private fun MethodChannel.Result.completeInstallation(
        installation: Map<String, Any?>?,
        failure: com.infobip.mobilemessaging.huawei.installation.InstallationFailure?,
    ) {
        if (failure == null) success(installation)
        else error(failure.code, failure.message, null)
    }

    private fun MethodChannel.Result.completeInbox(
        inbox: Map<String, Any?>?,
        failure: com.infobip.mobilemessaging.huawei.inbox.InboxFailure?,
    ) {
        if (failure == null) success(inbox)
        else error(failure.code, failure.message, null)
    }

    private fun detached(result: MethodChannel.Result) {
        result.error("native_error", "Plugin is not attached to an engine", null)
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
