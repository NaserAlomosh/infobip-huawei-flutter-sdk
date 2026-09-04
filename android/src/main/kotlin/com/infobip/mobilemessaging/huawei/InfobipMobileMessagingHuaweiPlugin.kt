package com.infobip.mobilemessaging.huawei

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.infobip.mobilemessaging.huawei.chat.ChatManager
import com.infobip.mobilemessaging.huawei.chat.ChatPlatformViewFactory
import com.infobip.mobilemessaging.huawei.core.MobileMessagingInitializer
import com.infobip.mobilemessaging.huawei.inbox.InboxManager
import com.infobip.mobilemessaging.huawei.installation.InstallationManager
import com.infobip.mobilemessaging.huawei.plugin.ChannelContract
import com.infobip.mobilemessaging.huawei.plugin.NativeEventBridge
import com.infobip.mobilemessaging.huawei.user.UserManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class InfobipMobileMessagingHuaweiPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware {
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var initializer: MobileMessagingInitializer? = null
    private var applicationContext: Context? = null
    private var eventBridge: NativeEventBridge? = null
    private var userManager: UserManager? = null
    private var installationManager: InstallationManager? = null
    private var inboxManager: InboxManager? = null
    private var chatManager: ChatManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        initializer = MobileMessagingInitializer(binding.applicationContext)
        userManager =
            UserManager(
                context = binding.applicationContext,
                isInitialized = { initializer?.isInitialized == true },
            )
        installationManager =
            InstallationManager(
                context = binding.applicationContext,
                isInitialized = { initializer?.isInitialized == true },
            )
        inboxManager =
            InboxManager(
                context = binding.applicationContext,
                isInitialized = { initializer?.isInitialized == true },
            )
        eventBridge = NativeEventBridge(binding.applicationContext).also { it.register() }
        chatManager =
            ChatManager(
                context = binding.applicationContext,
                initialized = { initializer?.isInitialized == true },
            )
        methodChannel =
            MethodChannel(binding.binaryMessenger, ChannelContract.METHOD_CHANNEL).also {
                it.setMethodCallHandler(this)
            }
        eventChannel =
            EventChannel(binding.binaryMessenger, ChannelContract.EVENT_CHANNEL).also {
                it.setStreamHandler(this)
            }
        binding.platformViewRegistry.registerViewFactory(
            ChannelContract.CHAT_VIEW,
            ChatPlatformViewFactory(
                messenger = binding.binaryMessenger,
                activityProvider = { activity },
                initialized = { initializer?.isInitialized == true },
            ),
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        eventBridge?.detach()
        chatManager?.detach()
        methodChannel = null
        eventChannel = null
        initializer = null
        eventBridge = null
        userManager = null
        installationManager = null
        inboxManager = null
        chatManager = null
        applicationContext = null
        activity = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            ChannelContract.INITIALIZE -> {
                initialize(call, result)
            }

            ChannelContract.REGISTER_FOR_REMOTE_NOTIFICATIONS -> {
                initializer?.registerForRemoteNotifications { error ->
                    mainHandler.post {
                        if (error == null) result.success(null)
                        else result.error(error.code, error.message, error.details)
                    }
                } ?: detached(result)
            }

            ChannelContract.GET_USER -> {
                userManager?.getUser { value, failure ->
                    result.completeUser(value, failure)
                }
                    ?: detached(result)
            }

            ChannelContract.FETCH_USER -> {
                userManager?.fetchUser { value, failure ->
                    result.completeUser(value, failure)
                }
                    ?: detached(result)
            }

            ChannelContract.SAVE_USER -> {
                userManager?.saveUser(
                    call.argument<Any?>(ChannelContract.USER),
                    { value, failure -> result.completeUser(value, failure) },
                ) ?: detached(result)
            }

            ChannelContract.PERSONALIZE -> {
                personalize(call, result)
            }

            ChannelContract.DEPERSONALIZE -> {
                userManager?.depersonalize { _, failure ->
                    if (failure == null) {
                        result.success(null)
                    } else {
                        result.error(failure.code, failure.message, null)
                    }
                } ?: detached(result)
            }

            ChannelContract.GET_INSTALLATION -> {
                installationManager?.getInstallation { value, failure ->
                    result.completeInstallation(value, failure)
                }
                    ?: detached(result)
            }

            ChannelContract.FETCH_INSTALLATION -> {
                installationManager?.fetchInstallation { value, failure ->
                    result.completeInstallation(value, failure)
                }
                    ?: detached(result)
            }

            ChannelContract.SAVE_INSTALLATION -> {
                installationManager?.saveInstallation(
                    call.argument<Any?>(ChannelContract.INSTALLATION),
                    { value, failure -> result.completeInstallation(value, failure) },
                ) ?: detached(result)
            }

            ChannelContract.FETCH_INBOX -> {
                inboxManager?.fetch(
                    call.argument<Any?>(ChannelContract.EXTERNAL_USER_ID),
                    call.argument<Any?>(ChannelContract.OPTIONS),
                    { value, failure -> result.completeInbox(value, failure) },
                ) ?: detached(result)
            }

            ChannelContract.SET_INBOX_MESSAGES_SEEN -> {
                inboxManager?.setSeen(
                    call.argument<Any?>(ChannelContract.EXTERNAL_USER_ID),
                    call.argument<Any?>(ChannelContract.MESSAGE_IDS),
                    { value, failure -> result.completeInbox(value, failure) },
                ) ?: detached(result)
            }

            ChannelContract.GET_CHAT_UNREAD_MESSAGE_COUNT -> {
                chatManager?.getUnreadMessageCount { count, failure ->
                    mainHandler.post {
                        if (failure == null) {
                            result.success(count)
                        } else {
                            result.error(failure.code, failure.message, null)
                        }
                    }
                } ?: detached(result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun personalize(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val force = call.argument<Boolean>(ChannelContract.FORCE_DEPERSONALIZE)
        if (force == null) {
            result.error("invalid_argument", "forceDepersonalize must be a boolean", null)
            return
        }
        userManager?.personalize(
            call.argument<Any?>(ChannelContract.USER_IDENTITY),
            call.argument<Any?>(ChannelContract.USER_ATTRIBUTES),
            force,
            { value, failure -> result.completeUser(value, failure) },
        ) ?: detached(result)
    }

    private fun MethodChannel.Result.completeUser(
        user: Map<String, Any?>?,
        failure: com.infobip.mobilemessaging.huawei.user.UserFailure?,
    ) {
        if (failure == null) {
            success(user)
        } else {
            error(failure.code, failure.message, null)
        }
    }

    private fun MethodChannel.Result.completeInstallation(
        installation: Map<String, Any?>?,
        failure: com.infobip.mobilemessaging.huawei.installation.InstallationFailure?,
    ) {
        if (failure == null) {
            success(installation)
        } else {
            error(failure.code, failure.message, null)
        }
    }

    private fun MethodChannel.Result.completeInbox(
        inbox: Map<String, Any?>?,
        failure: com.infobip.mobilemessaging.huawei.inbox.InboxFailure?,
    ) {
        if (failure == null) {
            success(inbox)
        } else {
            error(failure.code, failure.message, null)
        }
    }

    private fun detached(result: MethodChannel.Result) {
        result.error("native_error", "Plugin is not attached to an engine", null)
    }

    private fun initialize(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val applicationCode = call.argument<String>(ChannelContract.APPLICATION_CODE)
        if (applicationCode.isNullOrBlank()) {
            result.error("invalid_argument", "applicationCode must not be empty", null)
            return
        }

        initializer?.initialize(applicationCode) { error ->
            mainHandler.post {
                if (error == null) {
                    chatManager?.attach()
                    result.success(null)
                } else {
                    result.error(error.code, error.message, error.details)
                }
            }
        } ?: result.error("native_error", "Plugin is not attached to an engine", null)
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?,
    ) {
        eventBridge?.listen(events)
    }

    override fun onCancel(arguments: Any?) {
        eventBridge?.cancel()
    }
}
