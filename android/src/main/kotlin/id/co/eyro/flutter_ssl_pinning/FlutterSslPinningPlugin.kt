package id.co.eyro.flutter_ssl_pinning

import android.os.StrictMode
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.net.URL
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException
import java.security.cert.Certificate
import java.security.cert.CertificateEncodingException
import java.text.ParseException
import java.util.*
import javax.net.ssl.HttpsURLConnection
import javax.security.cert.CertificateException
import kotlin.collections.HashMap

/** FlutterSslPinningPlugin */
class FlutterSslPinningPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
        StrictMode.setThreadPolicy(policy)
        
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_ssl_pinning")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
              "validating" -> validating(call, result)
              else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error(e.toString(), "", "")
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


    @Throws(ParseException::class)
    private fun validating(call: MethodCall, result: Result) {

        if (call.arguments !is HashMap<*, *>) {
            result.error("INVALID_ARGUMENTS", null, null)
            return
        }
        val arguments: HashMap<*, *> = call.arguments as HashMap<*, *>

        val serverURL: String = arguments["url"] as String
        val allowedFingerprints: List<String> = arguments["fingerprints"] as List<String>
        val httpHeaderArgs: Map<String, String> = arguments["headers"] as Map<String, String>
        val timeout: Int = arguments["timeout"] as Int
        val type: String = arguments["type"] as String

        if (this.checkConnection(serverURL, allowedFingerprints, httpHeaderArgs, timeout, type)) {
            result.success(1)
        } else {
            result.error("CONNECTION_NOT_SECURED", null, null)
        }
    }


    private fun checkConnection(serverURL: String, allowedFingerprints: List<String>, httpHeaderArgs: Map<String, String>, timeout: Int, type: String): Boolean {
        val sha: String = this.getFingerprint(serverURL, timeout, httpHeaderArgs, type)
        return allowedFingerprints.map { fp -> fp.toUpperCase(Locale.ROOT).replace("\\s".toRegex(), "") }.contains(sha)
    }

    @Throws(IOException::class, NoSuchAlgorithmException::class, CertificateException::class, CertificateEncodingException::class)
    private fun getFingerprint(httpsURL: String, connectTimeout: Int, httpHeaderArgs: Map<String, String>, type: String): String {

        val url = URL(httpsURL)
        val httpClient: HttpsURLConnection = url.openConnection() as HttpsURLConnection
        httpClient.connectTimeout = connectTimeout * 1000
        httpHeaderArgs.forEach { (key, value) -> httpClient.setRequestProperty(key, value) }
        httpClient.connect()

        val cert: Certificate = httpClient.serverCertificates[0] as Certificate

        return this.hashString(type, cert.encoded)

    }

    private fun hashString(type: String, input: ByteArray) =
            MessageDigest
                    .getInstance(type.toUpperCase(Locale.ROOT))
                    .digest(input).joinToString(separator = "") { String.format("%02X", it) }
}
