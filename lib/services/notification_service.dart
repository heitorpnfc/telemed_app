import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine.dart';

const String _stopAlarmActionId = 'stop_medicine_alarm';

/// Executado quando o botão da notificação é pressionado
/// com o aplicativo fechado ou em segundo plano.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId == _stopAlarmActionId) {
    /*
     * A própria ação possui cancelNotification: true.
     * Ao cancelar a notificação, o Android também interrompe
     * o som insistente.
     */
    return;
  }
}

class NotificationService {
  static final NotificationService _instance =
      NotificationService._();

  factory NotificationService() => _instance;

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /*
   * Usamos um novo canal porque as configurações de som,
   * vibração e tipo de áudio ficam gravadas quando o canal
   * é criado pela primeira vez.
   */
  static const String _channelId =
    'medicine_alarm_channel_v4';

  static const String _channelName =
    'Alarmes de medicamentos';

  static const String _channelDescription =
    'Alarmes sonoros para lembrar o horário dos medicamentos';

  static const RawResourceAndroidNotificationSound _alarmSound =
      RawResourceAndroidNotificationSound(
    'remindcare_alarm',
  );

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;

    tz.initializeTimeZones();

    tz.setLocalLocation(
      tz.getLocation('America/Sao_Paulo'),
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,

      /*
       * Executado quando a notificação ou o botão é pressionado
       * com o aplicativo aberto.
       */
      onDidReceiveNotificationResponse:
          _handleNotificationResponse,

      /*
       * Executado quando o aplicativo está fechado
       * ou em segundo plano.
       */
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackground,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    /*
     * Define o canal como um canal de alarme.
     */

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        sound: _alarmSound,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint(
        'Não foi possível solicitar alarmes exatos: $e',
      );
    }

    _isInitialized = true;
  }

  void _handleNotificationResponse(
    NotificationResponse response,
  ) {
    if (response.actionId == _stopAlarmActionId) {
      /*
       * cancelNotification: true já remove a notificação.
       * Este callback permanece registrado para o Android
       * processar corretamente o botão.
       */
      return;
    }

    /*
     * Aqui você poderá futuramente abrir a página do remédio
     * quando o usuário tocar no corpo da notificação.
     */
  }

  NotificationDetails _buildAlarmNotificationDetails() {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,

      importance: Importance.max,
      priority: Priority.max,

      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,

      playSound: true,
      sound: _alarmSound,

      enableVibration: true,
      visibility: NotificationVisibility.public,

      autoCancel: false,
      ongoing: true,

      // FLAG_INSISTENT: repete o som até a notificação ser cancelada.
      additionalFlags: Int32List.fromList(
        <int>[4],
      ),

      // Para automaticamente depois de cinco minutos.
      timeoutAfter: 5 * 60 * 1000,

      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          _stopAlarmActionId,
          'PARAR',
          titleColor: Color(0xFFEF4444),
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    ),
  );
}

  Future<void> scheduleMedicineAlarms(
    List<Medicine> medicines,
  ) async {
    if (kIsWeb) return;

    if (!_isInitialized) {
      await init();
    }

    /*
     * Remove agendamentos antigos antes de recriar a agenda.
     */
    await _notificationsPlugin.cancelAll();

    int notificationId = 1000;

    for (final medicine in medicines) {
      final scheduledTime =
          medicine.scheduledTime.trim();

      if (scheduledTime.isEmpty) {
        continue;
      }

      final timeParts = scheduledTime.split(':');

      if (timeParts.length < 2) {
        debugPrint(
          'Horário inválido para ${medicine.name}: '
          '${medicine.scheduledTime}',
        );
        continue;
      }

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (hour == null ||
          minute == null ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        debugPrint(
          'Horário inválido para ${medicine.name}: '
          '${medicine.scheduledTime}',
        );
        continue;
      }

      for (final weekday in medicine.weekDays) {
        if (weekday < DateTime.monday ||
            weekday > DateTime.sunday) {
          continue;
        }

        await _scheduleWeekly(
          id: notificationId,
          title: 'Hora do remédio!',
          body:
              'Está na hora de tomar ${medicine.name} '
              '(${medicine.dosage}).',
          hour: hour,
          minute: minute,
          weekday: weekday,
          payload: medicine.name,
        );

        notificationId++;
      }
    }

    debugPrint(
      '${notificationId - 1000} alarmes de medicamentos agendados.',
    );
  }

  Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int weekday,
    required String payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    final daysUntilWeekday =
        (weekday - scheduledDate.weekday) % 7;

    scheduledDate = scheduledDate.add(
      Duration(days: daysUntilWeekday),
    );

    /*
     * Caso o horário de hoje já tenha passado,
     * agenda para a próxima semana.
     */
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(
        const Duration(days: 7),
      );
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails:
          _buildAlarmNotificationDetails(),
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );

    debugPrint(
      'Alarme $id agendado para $scheduledDate',
    );
  }

  /// Testa imediatamente o alarme, o aviso no topo
  /// e o botão "Parar alarme".
  Future<void> showTestNotification() async {
    if (kIsWeb) return;

    if (!_isInitialized) {
      await init();
    }

    await _notificationsPlugin.show(
      id: 999999,
      title: 'Hora do remédio!',
      body:
          'Este é um teste do alarme do RemindCare.',
      notificationDetails:
          _buildAlarmNotificationDetails(),
      payload: 'teste',
    );
  }

  Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    if (kIsWeb) return [];

    return _notificationsPlugin
        .pendingNotificationRequests();
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;

    await _notificationsPlugin.cancelAll();
  }
}