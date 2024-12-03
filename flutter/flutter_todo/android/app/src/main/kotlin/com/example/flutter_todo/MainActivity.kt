package com.example.flutter_todo

import io.flutter.embedding.android.FlutterActivity
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "forgerock.com/SampleBridge"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val frSampleBridgeChannel = FRAuthSampleBridge(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            // Note: this method is invoked on the main thread.
            when (call.method) {
                "frAuthStart" -> frSampleBridgeChannel.start(result)
                "login" -> frSampleBridgeChannel.login(result)
                "register" -> frSampleBridgeChannel.register(result)
                "logout" -> frSampleBridgeChannel.logout(result)
                "next" -> {
                    if (call.arguments is String) {
                        frSampleBridgeChannel.next(call.arguments as String, result)
                    } else {
                        result.error("500", "Arguments not parsed correctly", null)
                    }
                }
                "callEndpoint" -> {
                    if (call.arguments is ArrayList<*>) {
                        val args = call.arguments as ArrayList<String>
                        frSampleBridgeChannel.callEndpoint(args[0], args[1], args[2], result)
                    } else {
                        result.error("500", "Arguments not parsed correctly", null)
                    }
                }
                "getUserInfo" -> frSampleBridgeChannel.getUserInfo(result)
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}