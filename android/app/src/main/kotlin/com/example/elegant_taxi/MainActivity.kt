package com.example.elegant_taxi

import android.content.Context
import android.media.RingtoneManager
import android.net.Uri
import androidx.annotation.NonNull
import com.yandex.mapkit.MapKitFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.elegant_taxi/native"
    private val PREFS_NAME = "ElegantTaxiClientPrefs"
    private val DATA_KEY = "saved_app_data"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        try {
            // Eski loyihangizdagi Yandex MapKit API kalitini shu qatorga yozing:
            MapKitFactory.setApiKey("YANDEX_API_KEY_SHU_YERGA")
        } catch (e: Exception) {
            // Kalit allaqachon o'rnatilgan bo'lsa xato bermasligi uchun
        }
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveData" -> {
                    val data = call.argument<String>("data") ?: ""
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit().putString(DATA_KEY, data).apply()
                    result.success(true)
                }
                "loadData" -> {
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val saved = prefs.getString(DATA_KEY, "") ?: ""
                    result.success(saved)
                }
                "playSound" -> {
                    try {
                        val notification: Uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                        val r = RingtoneManager.getRingtone(applicationContext, notification)
                        r.play()
                    } catch (e: Exception) {}
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
