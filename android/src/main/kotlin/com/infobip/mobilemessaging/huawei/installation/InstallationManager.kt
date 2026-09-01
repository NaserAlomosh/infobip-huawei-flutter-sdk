package com.infobip.mobilemessaging.huawei.installation

import android.content.Context
import android.os.Handler
import android.os.Looper
import org.infobip.mobile.messaging.Installation
import org.infobip.mobile.messaging.MobileMessaging

internal class InstallationManager(
    context: Context,
    private val isInitialized: () -> Boolean,
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
) {
    private val mobileMessaging by lazy { MobileMessaging.getInstance(context) }

    fun getInstallation(callback: Callback) {
        if (!initialized(callback)) return
        execute("native_error", callback) { complete(callback, mobileMessaging.installation) }
    }

    fun fetchInstallation(callback: Callback) {
        if (!initialized(callback)) return
        execute("installation_fetch_failed", callback) {
            mobileMessaging.fetchInstallation { result ->
                if (result.isSuccess) complete(callback, result.data)
                else fail(callback, "installation_fetch_failed", "Unable to fetch installation")
            }
        }
    }

    fun saveInstallation(payload: Any?, callback: Callback) {
        if (!initialized(callback)) return
        execute("installation_save_failed", callback) {
            val installation = InstallationMapper.applyWritable(mobileMessaging.installation, payload)
            mobileMessaging.saveInstallation(installation) { result ->
                if (result.isSuccess) complete(callback, result.data)
                else fail(callback, "installation_save_failed", "Unable to save installation")
            }
        }
    }

    private fun initialized(callback: Callback): Boolean {
        if (isInitialized()) return true
        fail(callback, "not_initialized", "Initialize the Infobip SDK first")
        return false
    }

    private fun complete(callback: Callback, value: Installation) {
        mainHandler.post { callback(InstallationMapper.toMap(value), null) }
    }

    private fun fail(callback: Callback, code: String, message: String) {
        mainHandler.post { callback(null, InstallationFailure(code, message)) }
    }

    private inline fun execute(code: String, callback: Callback, operation: () -> Unit) {
        try {
            operation()
        } catch (_: IllegalArgumentException) {
            fail(callback, "invalid_argument", "Invalid installation payload")
        } catch (_: Exception) {
            fail(callback, code, "Installation operation failed")
        }
    }
}

internal typealias Callback = (Map<String, Any?>?, InstallationFailure?) -> Unit
internal data class InstallationFailure(val code: String, val message: String)
