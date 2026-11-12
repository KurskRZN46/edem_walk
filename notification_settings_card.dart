import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/step_provider.dart';
import '../services/notification_service.dart';

/// Карточка настроек умных напоминаний (v12).
/// Самостоятельно читает/пишет SharedPreferences и
/// перепланирует уведомления через [NotificationService].
class NotificationSettingsCard extends StatefulWidget {
  const NotificationSettingsCard({super.key});

  @override
  State<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard> {
  bool _daily = true;
  int _hour = 19;
  int _minute = 0;
  bool _evening = true;
  bool _streak = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _daily = prefs.getBool(NotificationService.kDailyEnabled) ?? true;
      _hour = prefs.getInt(NotificationService.kDailyHour) ?? 19;
      _minute = prefs.getInt(NotificationService.kDailyMinute) ?? 0;
      _evening = prefs.getBool(NotificationService.kEveningEnabled) ?? true;
      _streak = prefs.getBool(NotificationService.kStreakEnabled) ?? true;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationService.kDailyEnabled, _daily);
    await prefs.setInt(NotificationService.kDailyHour, _hour);
    await prefs.setInt(NotificationService.kDailyMinute, _minute);
    await prefs.setBool(NotificationService.kEveningEnabled, _evening);
    await prefs.setBool(NotificationService.kStreakEnabled, _streak);
    if (!mounted) return;
    final stepProvider = context.read<StepProvider>();
    await NotificationService.syncAll(
      steps: stepProvider.steps,
      goal: stepProvider.dailyGoal,
      streakDays: stepProvider.streakDays,
    );
  }

  String get _timeLabel =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      helpText: 'Время напоминания',
      cancelText: 'ОТМЕНА',
      confirmText: 'ГОТОВО',
    );
    if (picked == null) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color borderColor =
        isDark ? const Color(0xFF1E2730) : const Color(0xFFD0D5DD);
    final Color titleColor =
        isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2328);
    final Color subtitleColor =
        isDark ? const Color(0xFF8B98A5) : const Color(0xFF59636E);
    const Color accent = Color(0xFF00C853);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B23) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active,
                  color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                'УВЕДОМЛЕНИЯ',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _daily,
            activeThumbColor: accent,
            title: Text('Ежедневное напоминание',
                style: TextStyle(color: titleColor, fontSize: 14)),
            subtitle: Text('Позовёт на прогулку каждый день',
                style: TextStyle(color: subtitleColor, fontSize: 12)),
            onChanged: (v) async {
              setState(() => _daily = v);
              await _save();
            },
          ),
          if (_daily)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Время напоминания',
                          style:
                              TextStyle(color: titleColor, fontSize: 13)),
                    ),
                    Text(
                      _timeLabel,
                      style: const TextStyle(
                        color: accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, color: subtitleColor, size: 16),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _evening,
            activeThumbColor: accent,
            title: Text('Вечерний добив цели',
                style: TextStyle(color: titleColor, fontSize: 14)),
            subtitle: Text('В 18:00 напомнит, сколько шагов осталось',
                style: TextStyle(color: subtitleColor, fontSize: 12)),
            onChanged: (v) async {
              setState(() => _evening = v);
              await _save();
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _streak,
            activeThumbColor: accent,
            title: Text('Защита серии',
                style: TextStyle(color: titleColor, fontSize: 14)),
            subtitle: Text('В 20:00 предупредит, если серия может сгореть',
                style: TextStyle(color: subtitleColor, fontSize: 12)),
            onChanged: (v) async {
              setState(() => _streak = v);
              await _save();
            },
          ),
        ],
      ),
    );
  }
}
