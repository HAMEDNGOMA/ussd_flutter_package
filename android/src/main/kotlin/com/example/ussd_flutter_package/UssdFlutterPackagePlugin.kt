package com.example.ussd_flutter_package

import android.content.Context
import android.telephony.TelephonyManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class UssdFlutterPackagePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var ussdEventSink: EventChannel.EventSink? = null
  private var ussdCallback: TelephonyManager.UssdResponseCallback? = null
  private val mainHandler = Handler(Looper.getMainLooper())
  private val TAG = "UssdFlutterPlugin"

  // لمنع إرسال الرد أكثر من مرة
  private var isResultSent = false
  private var currentResult: MethodChannel.Result? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ussd_flutter_package")
    channel.setMethodCallHandler(this)

    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "ussd_flutter_package/events")
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        mainHandler.post {
          result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
      }
      "sendUssd" -> {
        val ussdCode = call.argument<String>("ussdCode")
        if (ussdCode != null) {
          sendUssdRequest(ussdCode, result)
        } else {
          mainHandler.post {
            result.error("INVALID_ARGUMENT", "ussdCode cannot be null", null)
          }
        }
      }
      "sendResponse" -> {
        val response = call.argument<String>("response")
        if (response != null) {
          sendUssdResponse(response, result)
        } else {
          mainHandler.post {
            result.error("INVALID_ARGUMENT", "response cannot be null", null)
          }
        }
      }
      "isUssdSupported" -> {
        isUssdSupported(result)
      }
      else -> {
        mainHandler.post {
          result.notImplemented()
        }
      }
    }
  }

  private fun sendUssdRequest(ussdCode: String, result: MethodChannel.Result) {
    Log.d(TAG, "sendUssd called with code: $ussdCode")
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
      mainHandler.post {
        result.error("UNSUPPORTED_API_VERSION", "USSD API is only supported on Android O (API 26) and above.", null)
      }
      return
    }

    val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

    // Reset state to accept new call
    isResultSent = false
    currentResult = result

    ussdCallback = object : TelephonyManager.UssdResponseCallback() {
      override fun onReceiveUssdResponse(telephonyManager: TelephonyManager, request: String, response: CharSequence) {
        super.onReceiveUssdResponse(telephonyManager, request, response)
        Log.d(TAG, "USSD response received: $response")
        val responseStr = response.toString()

        val isInteractive = responseStr.contains("\n") || responseStr.matches(Regex(".*\\d+.*"))

        mainHandler.post {
          if (!isResultSent) {
            isResultSent = true
            ussdEventSink?.success(mapOf(
              "message" to responseStr,
              "state" to if (isInteractive) "waiting_for_response" else "done"
            ))
            currentResult?.success(mapOf(
              "message" to responseStr,
              "state" to if (isInteractive) "waiting_for_response" else "done"
            ))
          } else {
            Log.w(TAG, "Result already sent, ignoring onReceiveUssdResponse")
          }
        }
      }

      override fun onReceiveUssdResponseFailed(telephonyManager: TelephonyManager, request: String, failureCode: Int) {
        super.onReceiveUssdResponseFailed(telephonyManager, request, failureCode)
        Log.e(TAG, "USSD response failed with code: $failureCode")
        mainHandler.post {
          if (!isResultSent) {
            isResultSent = true
            ussdEventSink?.error("USSD_FAILED", "USSD request failed with code: $failureCode", null)
            currentResult?.error("USSD_FAILED", "USSD request failed with code: $failureCode", null)
          }
        }
      }
    }

    Log.d(TAG, "Sending USSD request: $ussdCode")

    telephonyManager.sendUssdRequest(
      ussdCode,
      ussdCallback,
      null
    )
  }

  private fun sendUssdResponse(response: String, result: MethodChannel.Result) {
    Log.d(TAG, "sendUssdResponse called with response: $response")
    // NOTE: Android API does NOT provide official method to send USSD response interactively.
    // يمكن هنا مجرد رد Flutter بأن الرد تم استلامه
    mainHandler.post {
      result.success(mapOf("message" to "Response sent (not guaranteed)", "state" to "waiting_for_response"))
    }
  }

  private fun isUssdSupported(result: MethodChannel.Result) {
    val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
    val isSupported = telephonyManager.simState == TelephonyManager.SIM_STATE_READY &&
            telephonyManager.networkType != TelephonyManager.NETWORK_TYPE_UNKNOWN

    mainHandler.post {
      result.success(isSupported)
    }
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    ussdEventSink = events
  }

  override fun onCancel(arguments: Any?) {
    ussdEventSink = null
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }
}
