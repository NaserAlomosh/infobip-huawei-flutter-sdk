package com.infobip.mobilemessaging.huawei.inbox

import android.content.Context
import android.os.Handler
import android.os.Looper
import org.infobip.mobile.messaging.MobileMessaging
import org.infobip.mobile.messaging.inbox.Inbox
import org.infobip.mobile.messaging.inbox.MobileInbox
import org.infobip.mobile.messaging.mobileapi.MobileMessagingError
import org.infobip.mobile.messaging.mobileapi.Result

internal class InboxManager(
    context: Context,
    private val isInitialized: () -> Boolean,
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
) {
    private val mobileInbox by lazy { MobileInbox.getInstance(context) }

    fun fetch(
        externalUserIdValue: Any?,
        jwtValue: Any?,
        optionsValue: Any?,
        callback: InboxCallback,
    ) {
        if (!initialized(callback)) return
        try {
            val externalUserId = InboxMapper.requiredExternalUserId(externalUserIdValue)
            val jwt = InboxMapper.optionalJwt(jwtValue)
            val options = InboxMapper.nativeOptions(InboxMapper.parseOptions(optionsValue))
            if (jwt == null) {
                mobileInbox.fetchInbox(externalUserId, options, inboxListener(callback))
            } else {
                mobileInbox.fetchInbox(jwt, externalUserId, options, inboxListener(callback))
            }
        } catch (_: IllegalArgumentException) {
            fail(callback, "invalid_argument", "Invalid Inbox arguments")
        } catch (_: Exception) {
            fail(callback, "inbox_fetch_failed", "Unable to fetch Inbox")
        }
    }

    fun setSeen(externalUserIdValue: Any?, idsValue: Any?, callback: InboxCallback) {
        if (!initialized(callback)) return
        try {
            val externalUserId = InboxMapper.requiredExternalUserId(externalUserIdValue)
            val ids = InboxMapper.messageIds(idsValue).toTypedArray()
            mobileInbox.setSeen(
                externalUserId,
                ids,
                object : MobileMessaging.ResultListener<Array<String>>() {
                    override fun onResult(result: Result<Array<String>, MobileMessagingError>) {
                        if (result.isSuccess) complete(callback, null)
                        else fail(callback, "inbox_update_failed", "Unable to update Inbox")
                    }
                },
            )
        } catch (_: IllegalArgumentException) {
            fail(callback, "invalid_argument", "Invalid Inbox arguments")
        } catch (_: Exception) {
            fail(callback, "inbox_update_failed", "Unable to update Inbox")
        }
    }

    private fun inboxListener(callback: InboxCallback) =
        object : MobileMessaging.ResultListener<Inbox>() {
            override fun onResult(result: Result<Inbox, MobileMessagingError>) {
                val inbox = result.data
                if (result.isSuccess && inbox != null) complete(callback, InboxMapper.inbox(inbox))
                else fail(callback, "inbox_fetch_failed", "Unable to fetch Inbox")
            }
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
