// Фоновый сервис Android:
// - Подписывается на системный счётчик шагов TYPE_STEP_COUNTER
// - Считает шаги за сегодня
// - Показывает уведомление
// - Сохраняет результаты в SharedPreferences

package com.example.soccer_pedometer_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// Получает события от датчика шагов
class StepCounterService : Service(), SensorEventListener {
    private lateinit var sensorManager: SensorManager // Менеджер сенсоров, через которырй получаем доступ к TYPE_STEP_COUNTER
    private var stepCounterSensor: Sensor? = null // Сам сенсор шагов
    private lateinit var prefs: SharedPreferences // Хранилище ключ-значение — куда пишем и откуда читаем шаги/baseline (значение счётчика на момент, когда начался отсчёт)
    private var wakeLock: PowerManager.WakeLock? = null // Блокировка, не дающая процессору уснуть во время работы сервиса

    private var baselineSteps = 0 // Значение счётчика в момент старта отслеживания
    private var baselineDate = "" // Дата, когда был установлен baseline
    private var todaySteps = 0 // Шагов за сегодня
    private var resetFlag = false // Флаг, что пользователь нажал сбросить статистику

    // Статические константы
    companion object {
        const val CHANNEL_ID = "step_counter_channel"
        const val NOTIFICATION_ID = 1
        const val PREFS_NAME = "step_counter_prefs"
        var isRunning = false
    }

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
        stepCounterSensor = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        loadState()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildNotification(todaySteps)

        // Запускаем сервис как foreground с уведомлением. На Android 14+ (API 34) нужно указать тип foreground-сервиса
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        isRunning = true

        // Берём PowerManager и создаём WakeLock, чтобы процессор не засыпал и сенсор продолжал отдавать события
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK, // Экран может гаснуть, CPU работает
            "SoccerPedometer::StepCounterWakeLock" // Просто метка для отладки
        )
        wakeLock?.acquire() // Захватываем блокировку

        // Если сенсор есть, регистрируем слушателя
        if (stepCounterSensor != null) {
            sensorManager.registerListener(
                this, // Кто слушает
                stepCounterSensor, // Что слушаем
                SensorManager.SENSOR_DELAY_NORMAL // Как часто
            )
        }

        return START_STICKY // Если система убьёт сервис, она его перезапустит
    }

    override fun onDestroy() {
        sensorManager.unregisterListener(this)
        wakeLock?.release()
        wakeLock = null
        saveState()
        isRunning = false
        super.onDestroy()
    }

    // Вызывается каждый раз, когда сенсор отдаёт новое значение, т.е. пользователь проходит шаг
    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_STEP_COUNTER) {
            val totalSteps = event.values[0].toInt() // Это общее число шагов с момента загрузки телефона
            val today = getTodayString()

            resetFlag = prefs.getBoolean("reset_flag", false)

            if (today != baselineDate) { // Сменился день
                baselineDate = today
                baselineSteps = totalSteps
                todaySteps = 0
            } else if (resetFlag) { // Пользователь сам сбросил
                baselineSteps = totalSteps
                todaySteps = 0
                resetFlag = false
                prefs.edit().putBoolean("reset_flag", false).apply()
            } else {
                if (totalSteps < baselineSteps) {
                    baselineSteps = totalSteps - todaySteps
                }
                todaySteps = totalSteps - baselineSteps
                if (todaySteps < 0) todaySteps = 0
            }

            saveState()
            updateNotification(todaySteps)
        }
    }

    // Просто обязательный метод. Можете идти дальше
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onBind(intent: Intent?): IBinder? = null

    private fun loadState() {
        baselineSteps = prefs.getInt("baseline_steps", 0)
        baselineDate = prefs.getString("baseline_date", "") ?: ""
        todaySteps = prefs.getInt("today_steps", 0)
        resetFlag = prefs.getBoolean("reset_flag", false)
    }

    private fun saveState() {
        prefs.edit()
            .putInt("baseline_steps", baselineSteps)
            .putString("baseline_date", baselineDate)
            .putInt("today_steps", todaySteps)
            .apply() // Для асинхронной записи
    }

    private fun getTodayString(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return sdf.format(Date())
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Счётчик шагов",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Отслеживание шагов в фоновом режиме"
                setShowBadge(false) // Убрать бесячую точку у иконки
            }
            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(steps: Int): Notification {
        val goal = prefs.getInt("daily_goal", 10000)

        val intent = packageManager.getLaunchIntentForPackage(packageName) // Что открыть при клике на уведомление (главную активити)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, flags) // Отложенное действие (открыть приложение при клике)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Шагомер активен")
            .setContentText("Шагов сегодня: $steps / $goal")
            .setSmallIcon(R.drawable.ic_step)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setSilent(true)
            .build()
    }

    private fun updateNotification(steps: Int) {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(steps))
    }
}