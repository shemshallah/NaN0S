package org.nan0s.vm

import android.content.Context
import java.io.Closeable
import java.net.URI

/**
 * One serialized N16T exchange over the opaque HTTPS adapter.
 *
 * The guest builds the request. The transport moves bytes only. After a successful
 * HTTP exchange, the guest commits the outbound transition and validates/routes the
 * peer frame. No protocol fields are decoded in this Kotlin coordinator.
 */
internal class N16RemoteSession(
    context: Context,
    endpoint: URI
) : Closeable {
    data class ExchangeResult(
        val peerFrame: ByteArray,
        val route: N16GuestProtocol.Route
    )

    private val guest = N16GuestProtocol(context)
    private val transport = N16HttpsTransport(endpoint)
    private var closed = false

    @Synchronized
    fun exchange(type: Int, payload: ByteArray): ExchangeResult {
        check(!closed) { "N16 remote session is closed" }
        val request = guest.buildFrame(type, payload)
        try {
            val response = transport.exchange(request)
            guest.commitSent()
            val route = guest.acceptFrame(response)
            return ExchangeResult(response, route)
        } catch (failure: Exception) {
            // If HTTPS failed, the guest has not committed the outbound transition.
            // If it succeeded but peer validation failed, abortPending is a no-op.
            try { guest.abortPending() } catch (_: Exception) { }
            throw failure
        }
    }

    @Synchronized
    fun resetSession() {
        check(!closed) { "N16 remote session is closed" }
        guest.resetSession()
    }

    @Synchronized
    override fun close() {
        if (!closed) {
            closed = true
            guest.close()
        }
    }
}
