// Перезапускает сервис шагомера после перезагрузки телефона,
// если пользователь оставил подсчёт включённым.

package com.example.soccer_pedometer_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            val prefs = context.getSharedPreferences(
                StepCounterService.PREFS_NAME, Context.MODE_PRIVATE
            )
            // Сервис перезапускаем только если пользователь его не выключал
            val enabled = prefs.getBoolean("service_enabled", false)
            if (enabled) {
                val serviceIntent = Intent(context, StepCounterService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
