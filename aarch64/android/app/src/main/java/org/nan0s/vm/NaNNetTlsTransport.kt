package org.nan0s.vm

import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.net.InetSocketAddress
import javax.net.ssl.SNIHostName
import javax.net.ssl.SSLSocket
import javax.net.ssl.SSLSocketFactory

/**
 * TLS transport shim. It only moves bounded N16T frames; the NaN16 guest
 * remains responsible for magic/version/type/sequence/CRC and route policy.
 * No bearer token or GitHub credential is stored by this class.
 */
object NaNNetTlsTransport {
    private const val HEADER_BYTES = 32
    private const val TRAILER_BYTES = 4
    private const val MAX_PAYLOAD = 1_048_576
    private const val MAX_FRAME = HEADER_BYTES + MAX_PAYLOAD + TRAILER_BYTES

    fun exchange(host: String, port: Int, request: ByteArray): ByteArray {
        require(host.isNotBlank() && port in 1..65535)
        require(request.size in (HEADER_BYTES + TRAILER_BYTES)..MAX_FRAME)
        val socket = SSLSocketFactory.getDefault().createSocket() as SSLSocket
        socket.use {
            socket.connect(InetSocketAddress(host, port), 10_000)
            socket.soTimeout = 15_000
            val parameters = socket.sslParameters
            parameters.endpointIdentificationAlgorithm = "HTTPS"
            parameters.serverNames = listOf(SNIHostName(host))
            socket.sslParameters = parameters
            socket.startHandshake()
            writeAll(socket.outputStream, request)
            socket.outputStream.flush()
            val header = readExact(socket.inputStream, HEADER_BYTES)
            val payloadLength = (header[28].toInt() and 255) or
                ((header[29].toInt() and 255) shl 8) or
                ((header[30].toInt() and 255) shl 16) or
                ((header[31].toInt() and 255) shl 24)
            require(payloadLength in 0..MAX_PAYLOAD) { "N16T frame length rejected" }
            val body = readExact(socket.inputStream, payloadLength + TRAILER_BYTES)
            return header + body
        }
    }

    fun exchangeFromGuest(
        vm: NanVm,
        host: String,
        port: Int,
        requestAddress: Int,
        requestLength: Int,
        responseAddress: Int
    ): ByteArray {
        val request = vm.extractNetworkFrame(requestAddress, requestLength)
            ?: throw IllegalStateException("NaN16 request frame unavailable")
        val response = exchange(host, port, request)
        if (!vm.stageNetworkFrame(responseAddress, response)) {
            throw IllegalStateException("NaN16 response frame could not be staged")
        }
        return response
    }

    private fun writeAll(output: OutputStream, bytes: ByteArray) {
        output.write(bytes)
    }

    private fun readExact(input: InputStream, length: Int): ByteArray {
        val out = ByteArray(length)
        var offset = 0
        while (offset < length) {
            val count = input.read(out, offset, length - offset)
            if (count < 0) throw IllegalStateException("Remote training peer closed mid-frame")
            if (count == 0) continue
            offset += count
        }
        return out
    }
}
