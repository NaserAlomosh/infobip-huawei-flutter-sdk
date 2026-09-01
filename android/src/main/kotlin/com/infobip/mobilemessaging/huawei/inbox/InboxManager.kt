package com.infobip.mobilemessaging.huawei.inbox

import android.content.Context
import android.os.Handler
import android.os.Looper
import java.lang.reflect.Proxy

internal class InboxManager(
    private val context: Context,
    private val isInitialized: () -> Boolean,
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
) {
    private val mobileInbox: Any by lazy {
        val type = Class.forName("org.infobip.mobile.messaging.inbox.MobileInbox")
        type.getMethod("getInstance", Context::class.java).invoke(null, context)
    }

    fun fetch(optionsValue: Any?, callback: InboxCallback) {
        if (!initialized(callback)) return
        try {
            val options = nativeOptions(InboxMapper.parseOptions(optionsValue))
            invokeAsync("fetchInbox", options) { result ->
                val data = resultData(result)
                if (data != null) complete(callback, InboxMapper.inbox(data))
                else fail(callback, "inbox_fetch_failed", "Unable to fetch Inbox")
            }
        } catch (_: IllegalArgumentException) {
            fail(callback, "invalid_argument", "Invalid Inbox options")
        } catch (_: Exception) {
            fail(callback, "inbox_fetch_failed", "Unable to fetch Inbox")
        }
    }

    fun setSeen(idsValue: Any?, callback: InboxCallback) {
        if (!initialized(callback)) return
        try {
            val ids = InboxMapper.messageIds(idsValue).toTypedArray()
            invokeAsync("setSeen", ids) { result ->
                if (resultSuccess(result)) complete(callback, null)
                else fail(callback, "inbox_update_failed", "Unable to update Inbox")
            }
        } catch (_: IllegalArgumentException) {
            fail(callback, "invalid_argument", "Invalid Inbox message identifiers")
        } catch (_: Exception) {
            fail(callback, "inbox_update_failed", "Unable to update Inbox")
        }
    }

    private fun nativeOptions(options: InboxOptions): Any {
        val type = Class.forName("org.infobip.mobile.messaging.inbox.InboxFilterOptions")
        val constructor = type.constructors.firstOrNull { it.parameterCount == 4 }
            ?: throw IllegalStateException("Unsupported Inbox SDK")
        return constructor.newInstance(options.from, options.to, options.topic, options.limit)
    }

    private fun invokeAsync(name: String, argument: Any, completion: (Any?) -> Unit) {
        val method = mobileInbox.javaClass.methods.firstOrNull {
            it.name == name && it.parameterCount == 2
        } ?: throw IllegalStateException("Unsupported Inbox SDK")
        val callbackType = method.parameterTypes[1]
        val proxy = Proxy.newProxyInstance(callbackType.classLoader, arrayOf(callbackType)) { _, called, args ->
            if (called.name != "toString" && called.name != "hashCode" && called.name != "equals") {
                completion(args?.firstOrNull())
            }
            null
        }
        val nativeArgument = when {
            method.parameterTypes[0].isArray && argument is Array<*> -> argument
            List::class.java.isAssignableFrom(method.parameterTypes[0]) && argument is Array<*> ->
                argument.toList()
            else -> argument
        }
        method.invoke(mobileInbox, nativeArgument, proxy)
    }

    private fun resultSuccess(result: Any?): Boolean =
        result?.javaClass?.methods?.firstOrNull { it.name == "isSuccess" && it.parameterCount == 0 }
            ?.invoke(result) as? Boolean == true

    private fun resultData(result: Any?): Any? {
        if (!resultSuccess(result)) return null
        return result?.javaClass?.methods
            ?.firstOrNull { it.name == "getData" && it.parameterCount == 0 }?.invoke(result)
    }

    private fun initialized(callback: InboxCallback): Boolean {
        if (isInitialized()) return true
        fail(callback, "not_initialized", "Initialize the Infobip SDK first")
        return false
    }

    private fun complete(callback: InboxCallback, value: Map<String, Any?>?) {
        mainHandler.post { callback(value, null) }
    }

    private fun fail(callback: InboxCallback, code: String, message: String) {
        mainHandler.post { callback(null, InboxFailure(code, message)) }
    }
}

internal typealias InboxCallback = (Map<String, Any?>?, InboxFailure?) -> Unit
internal data class InboxFailure(val code: String, val message: String)
