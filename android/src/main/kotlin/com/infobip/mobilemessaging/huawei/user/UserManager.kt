package com.infobip.mobilemessaging.huawei.user

import android.content.Context
import android.os.Handler
import android.os.Looper
import org.infobip.mobile.messaging.MobileMessaging
import org.infobip.mobile.messaging.UserAttributes
import org.infobip.mobile.messaging.UserIdentity

internal class UserManager(
    context: Context,
    private val isInitialized: () -> Boolean,
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
) {
    private val mobileMessaging by lazy { MobileMessaging.getInstance(context) }

    fun getUser(callback: (Map<String, Any?>?, UserFailure?) -> Unit) {
        if (!initialized(callback)) return
        execute("native_error", callback) { complete(callback, mobileMessaging.user) }
    }

    fun fetchUser(callback: (Map<String, Any?>?, UserFailure?) -> Unit) {
        if (!initialized(callback)) return
        execute("user_fetch_failed", callback) {
            mobileMessaging.fetchUser { result ->
                if (result.isSuccess) complete(callback, result.data)
                else fail(callback, "user_fetch_failed", "Unable to fetch user")
            }
        }
    }

    fun saveUser(value: Any?, callback: (Map<String, Any?>?, UserFailure?) -> Unit) {
        if (!initialized(callback)) return
        execute("invalid_argument", callback) {
            val user = UserMapper.toUser(value)
            mobileMessaging.saveUser(user) { result ->
                if (result.isSuccess) complete(callback, result.data)
                else fail(callback, "user_save_failed", "Unable to save user")
            }
        }
    }

    fun personalize(
        identityValue: Any?,
        attributesValue: Any?,
        forceDepersonalize: Boolean,
        callback: (Map<String, Any?>?, UserFailure?) -> Unit,
    ) {
        if (!initialized(callback)) return
        execute("invalid_argument", callback) {
            val identity: UserIdentity = UserMapper.toIdentity(identityValue)
            val attributes: UserAttributes? = UserMapper.toAttributes(attributesValue)
            mobileMessaging.personalize(identity, attributes, forceDepersonalize) { result ->
                if (result.isSuccess) complete(callback, result.data)
                else fail(callback, "personalization_failed", "Unable to personalize user")
            }
        }
    }

    fun depersonalize(callback: (Map<String, Any?>?, UserFailure?) -> Unit) {
        if (!initialized(callback)) return
        execute("depersonalization_failed", callback) {
            mobileMessaging.depersonalize { result ->
                if (result.isSuccess) mainHandler.post { callback(emptyMap(), null) }
                else fail(callback, "depersonalization_failed", "Unable to depersonalize user")
            }
        }
    }

    private fun initialized(callback: (Map<String, Any?>?, UserFailure?) -> Unit): Boolean {
        if (isInitialized()) return true
        fail(callback, "not_initialized", "Initialize the Infobip SDK first")
        return false
    }

    private fun complete(callback: (Map<String, Any?>?, UserFailure?) -> Unit, user: org.infobip.mobile.messaging.User) {
        mainHandler.post { callback(UserMapper.toMap(user), null) }
    }

    private fun fail(callback: (Map<String, Any?>?, UserFailure?) -> Unit, code: String, message: String) {
        mainHandler.post { callback(null, UserFailure(code, message)) }
    }

    private inline fun execute(
        code: String,
        callback: (Map<String, Any?>?, UserFailure?) -> Unit,
        operation: () -> Unit,
    ) {
        try {
            operation()
        } catch (_: IllegalArgumentException) {
            fail(callback, "invalid_argument", "Invalid user payload")
        } catch (_: Exception) {
            fail(callback, code, "User operation failed")
        }
    }
}

internal data class UserFailure(val code: String, val message: String)
