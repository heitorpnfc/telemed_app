import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/medicine.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) return;

    tz.initializeTimeZones();
    // Assuming local timezone is America/Sao_Paulo for simplicity, but ideally we get it dynamically.
    // Using a simpler approach: get local timezone if possible, but package timezone doesn't have auto detect without flutter_native_timezone.
    // So we just use UTC offsets or default to local location. 
    // Usually tz.setLocalLocation is needed. For now, we will use default local.
    // We can rely on basic initialization.

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
    
    // Request permission (Android 13+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  Future<void> scheduleMedicineAlarms(List<Medicine> medicines) async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancelAll(); // Reset previous alarms

    int notificationId = 0;

    for (final med in medicines) {
      if (med.scheduledTime.isEmpty) continue;
      
      final parts = med.scheduledTime.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      for (final weekDay in med.weekDays) {
        // weekDay: 1 (Mon) to 7 (Sun)
        // DateTime.monday = 1, DateTime.sunday = 7
        await _scheduleWeekly(
          id: notificationId++,
          title: 'Hora do Remédio!',
          body: 'Está na hora de tomar: ${med.name} (${med.dosage})',
          hour: hour,
          minute: minute,
          weekday: weekDay,
        );
      }
    }
  }

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int weekday,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Adjust day of week
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_channel_id',
          'Avisos de Remédio',
          channelDescription: 'Canal para alertas de medicamentos',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
