package com.example.grade_calculator

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Channel name must match what you call from Dart
    private val CHANNEL = "com.example.grade_calculator/info"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel: lets Dart call Kotlin functions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceInfo" -> {
                        val info = mapOf(
                            "brand"   to android.os.Build.BRAND,
                            "model"   to android.os.Build.MODEL,
                            "version" to android.os.Build.VERSION.RELEASE,
                            "sdk"     to android.os.Build.VERSION.SDK_INT.toString()
                        )
                        result.success(info)
                    }
                    "getAppVersion" -> {
                        val pInfo = packageManager.getPackageInfo(packageName, 0)
                        result.success(pInfo.versionName)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}