// Сервис локальных напоминаний (пуши без сервера):
// - ежедневное напоминание «Время прогулки» в выбранное время
// - вечерний пуш «осталось N шагов до цели» (если цель не выполнена)
// - защита серии: «Серия N дней сгорит сегодня!» (если день ещё пустой)
//
// Всё локально: flutter_local_notifications планирует пуши на устройстве,
// никаких серверов и отправки данных.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Ключи настроек в SharedPreferences
  static const kDailyEnabled = 'notif_daily_enabled'; // напоминание о прогулке
  static const kDailyHour = 'notif_daily_hour';
  static const kDailyMinute = 'notif_daily_minute';
  static const kEveningEnabled = 'notif_evening_enabled'; // «осталось N шагов»
  static const kStreakEnabled = 'notif_streak_enabled'; // защита серии

  // ID уведомлений
  static const _idDaily = 1;
  static const _idEvening = 2;
  static const _idStreak = 3;

  static bool _initialized = false;

  // Разовая инициализация при запуске приложения
  static Future<void> init() async {
    if (_initialized) return;

    // Часовой пояс: берём по смещению устройства (Etc/GMT-3 = UTC+3,
    // у Etc-зон знак перевёрнут). Дробные смещения округляем.
    tz_data.initializeTimeZones();
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    final zoneName = offsetHours == 0 ? 'UTC' : 'Etc/GMT${offsetHours > 0 ? '-' : '+'}${offsetHours.abs()}';
    try {
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      // Если зона не нашлась (редкие дробные смещения) - остаёмся на UTC
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // запросим позже через онбординг
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );

    // Запрос разрешения на уведомления (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // Ближайшее наступление времени ЧЧ:ММ (сегодня или завтра)
  static tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static const _channel = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Напоминания',
      channelDescription: 'Напоминания о прогулках и целях',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  // Ежедневное напоминание о прогулке
  static Future<void> _scheduleDaily(int hour, int minute) async {
    await _plugin.zonedSchedule(
      _idDaily,
      'Edem Walk',
      'Стадион ждёт! Пора на прогулку',
      _nextTime(hour, minute),
      _channel,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // повторять каждый день
    );
  }

  // Вечерний пуш: если цель не выполнена - сколько осталось
  static Future<void> _scheduleEvening(int steps, int goal) async {
    final remaining = goal - steps;
    if (remaining <= 0) return; // цель выполнена - не беспокоим
    await _plugin.zonedSchedule(
      _idEvening,
      'Добей цель!',
      'Осталось $remaining шагов до цели - это пара улиц',
      _nextTime(18, 0),
      _channel,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // Защита серии: вечером напоминаем, если день пустой
  static Future<void> _scheduleStreakSave(int streakDays, int steps) async {
    if (streakDays <= 0 || steps > 0) return; // нечего защищать / день уже есть
    await _plugin.zonedSchedule(
      _idStreak,
      'Серия в опасности!',
      'Твоя серия $streakDays дн. сгорит сегодня. Пройди хотя бы немного',
      _nextTime(20, 0),
      _channel,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // Главная точка: перечитать настройки и перепланировать все пуши
  // под актуальное состояние (вызывается при старте и периодически)
  static Future<void> syncAll({
    required int steps,
    required int goal,
    required int streakDays,
  }) async {
    if (!_initialized) return;
    final prefs = await SharedPreferences.getInstance();

    // Сначала снимаем все старые планировки
    await _plugin.cancel(_idDaily);
    await _plugin.cancel(_idEvening);
    await _plugin.cancel(_idStreak);

    // 1. Ежедневное напоминание
    if (prefs.getBool(kDailyEnabled) ?? true) {
      await _scheduleDaily(
        prefs.getInt(kDailyHour) ?? 19,
        prefs.getInt(kDailyMinute) ?? 0,
      );
    }

    // 2. Вечерний «добей цель»
    if (prefs.getBool(kEveningEnabled) ?? true) {
      await _scheduleEvening(steps, goal);
    }

    // 3. Защита серии
    if (prefs.getBool(kStreakEnabled) ?? true) {
      await _scheduleStreakSave(streakDays, steps);
    }
  }

  // Выключить все напоминания
  static Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}
