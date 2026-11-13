// Главная активити Android, где:
// - Запускается Flutter-движок
// - Создаётся MethodChannel step_counter (мост между Dart и Kotlin)
// - Обрабатываются вызовы из Dart
// (кароче аналог AppDelegate.swift на iOS)

package com.example.soccer_pedometer_app

import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    // Имя канала. Должно совпадать с Dart (step_service.dart) и iOS (AppDelegate.swift)
    private val CHANNEL = "step_counter"

    // Вызывается Flutter 1 раз при инициализации движка
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val prefs = getSharedPreferences(StepCounterService.PREFS_NAME, MODE_PRIVATE)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val intent = Intent(this, StepCounterService::class.java)
                    // На Android 8 (O) и выше сервис с уведомлением нужно запускать через startForegroundService, иначе краш. Они немного цундере
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    // Запоминаем, что пользователь включил подсчёт -
                    // BootReceiver поднимет сервис после перезагрузки телефона
                    prefs.edit().putBoolean("service_enabled", true).apply()
                    result.success(true)
                }
                "stopService" -> {
                    val intent = Intent(this, StepCounterService::class.java)
                    stopService(intent)
                    prefs.edit().putBoolean("service_enabled", false).apply()
                    result.success(true)
                }
                "getSteps" -> {
                    val today = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                        .format(Date())
                    val baselineDate = prefs.getString("baseline_date", "") ?: ""
                    if (today != baselineDate) {
                        // День сменился, но сенсор ещё не сработал — 
                        // обнуляем today_steps, но НЕ трогаем baseline_date.
                        // onSensorChanged сам сбросит baselineSteps при первом событии.
                        prefs.edit()
                            .putInt("today_steps", 0)
                            .apply()
                        result.success(0)
                    } else {
                        result.success(prefs.getInt("today_steps", 0))
                    }
                }
                "getDailyGoal" -> {
                    result.success(prefs.getInt("daily_goal", 10000))
                }
                "setDailyGoal" -> {
                    val goal = call.argument<Int>("goal") ?: 10000
                    prefs.edit().putInt("daily_goal", goal).apply()
                    result.success(true)
                }
                "isRunning" -> {
                    result.success(StepCounterService.isRunning)
                }
                "resetCounter" -> {
                    prefs.edit()
                        .putInt("today_steps", 0)
                        .putBoolean("reset_flag", true)
                        .apply()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
