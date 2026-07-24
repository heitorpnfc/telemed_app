import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';

import '../models/medicine.dart';

class MedicineAlarmService {
  static const String _audioPath =
      'assets/audio/remindcare_alarm.mp3';

  static const String _payloadType = 'medicine_alarm';

  // Agenda os próximos cinco ciclos semanais.
  static const int _daysAhead = 35;

  /// Remove os agendamentos antigos dos medicamentos e cria
  /// novamente os alarmes com base na lista atualizada.
  static Future<void> syncMedicineAlarms(
    List<Medicine> medicines,
  ) async {
    final existingAlarms = await Alarm.getAlarms();

    final usedIds = <int>{};

    /*
     * Remove somente alarmes criados por este serviço.
     * Alarmes que estejam tocando não são interrompidos.
     */
    for (final alarm in existingAlarms) {
      if (_isMedicineAlarm(alarm)) {
        final isRinging = await Alarm.isRinging(alarm.id);

        if (isRinging) {
          usedIds.add(alarm.id);
        } else {
          await Alarm.stop(alarm.id);
        }
      } else {
        // Preserva alarmes criados por outras partes do aplicativo.
        usedIds.add(alarm.id);
      }
    }

    final now = DateTime.now();

    /*
     * Agrupa remédios que possuem exatamente o mesmo
     * dia e horário em um único alarme.
     */
    final groups = <String, _MedicineAlarmGroup>{};

    for (final medicine in medicines) {
      final parsedTime = _parseTime(
        medicine.scheduledTime,
      );

      if (parsedTime == null) {
        debugPrint(
          'Horário inválido para ${medicine.name}: '
          '${medicine.scheduledTime}',
        );
        continue;
      }

      for (int offset = 0; offset < _daysAhead; offset++) {
        final day = DateTime(
          now.year,
          now.month,
          now.day + offset,
        );

        if (!medicine.weekDays.contains(day.weekday)) {
          continue;
        }

        final alarmDate = DateTime(
          day.year,
          day.month,
          day.day,
          parsedTime.hour,
          parsedTime.minute,
        );

        // Não agenda horários que já passaram.
        if (!alarmDate.isAfter(now)) {
          continue;
        }

        final groupKey =
            alarmDate.millisecondsSinceEpoch.toString();

        final group = groups.putIfAbsent(
          groupKey,
          () => _MedicineAlarmGroup(
            dateTime: alarmDate,
          ),
        );

        group.medicines.add(medicine);
      }
    }

    final orderedGroups = groups.values.toList()
      ..sort(
        (a, b) => a.dateTime.compareTo(b.dateTime),
      );

    int scheduledCount = 0;

    for (final group in orderedGroups) {
      final medicineIds = group.medicines
          .map((medicine) => medicine.id)
          .toList()
        ..sort();

      final identifierSource = [
        group.dateTime.millisecondsSinceEpoch,
        ...medicineIds,
      ].join('|');

      int alarmId = _createStableId(identifierSource);

      // Evita colisão com outro alarme existente.
      while (usedIds.contains(alarmId)) {
        alarmId++;

        if (alarmId >= 2147483647) {
          alarmId = 1;
        }
      }

      usedIds.add(alarmId);

      final settings = AlarmSettings(
        id: alarmId,
        dateTime: group.dateTime,
        assetAudioPath: _audioPath,

        // Repete o áudio até o botão PARAR ser pressionado.
        loopAudio: true,

        // Repete a vibração até o alarme ser parado.
        vibrate: true,

        // Acende a tela e apresenta o aviso do alarme.
        androidFullScreenIntent: true,

        // Mantém o alarme mesmo que o app seja removido dos recentes.
        androidStopAlarmOnTermination: false,

        warningNotificationOnKill: false,

        // Se houver dois alarmes no mesmo momento,
        // o próximo aguardará o atual ser encerrado.
        allowAlarmOverlap: false,

        volumeSettings: const VolumeSettings.fixed(
          volume: 1.0,
          volumeEnforced: false,
          showSystemUI: false,
        ),

        notificationSettings: NotificationSettings(
          title: 'Hora do remédio!',
          body: _createNotificationBody(
            group.medicines,
          ),
          stopButton: 'PARAR ALARME',
        ),

        payload: jsonEncode({
          'type': _payloadType,
          'dateTime': group.dateTime.toIso8601String(),
          'medicineIds': medicineIds,
        }),
      );

      try {
        final success = await Alarm.set(
          alarmSettings: settings,
        );

        if (success) {
          scheduledCount++;
        } else {
          debugPrint(
            'Não foi possível agendar o alarme $alarmId.',
          );
        }
      } catch (error) {
        debugPrint(
          'Erro ao agendar alarme $alarmId: $error',
        );
      }
    }

    debugPrint(
      '$scheduledCount alarmes de medicamentos agendados.',
    );
  }

  /// Remove todos os alarmes dos medicamentos.
  ///
  /// Deve ser chamado ao sair da conta para evitar que os alarmes
  /// do usuário anterior continuem agendados.
  static Future<void> cancelMedicineAlarms() async {
    final alarms = await Alarm.getAlarms();

    for (final alarm in alarms) {
      if (_isMedicineAlarm(alarm)) {
        await Alarm.stop(alarm.id);
      }
    }
  }

  /// Mantido somente para testes manuais.
  static Future<void> scheduleTestAlarm() async {
    const testAlarmId = 999999;

    await Alarm.stop(testAlarmId);

    final settings = AlarmSettings(
      id: testAlarmId,
      dateTime: DateTime.now().add(
        const Duration(seconds: 5),
      ),
      assetAudioPath: _audioPath,
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      androidStopAlarmOnTermination: false,
      warningNotificationOnKill: false,
      volumeSettings: const VolumeSettings.fixed(
        volume: 1.0,
        volumeEnforced: false,
        showSystemUI: false,
      ),
      notificationSettings: const NotificationSettings(
        title: 'Hora do remédio!',
        body: 'Este é um teste do alarme do RemindCare.',
        stopButton: 'PARAR ALARME',
      ),
      payload: jsonEncode({
        'type': 'test_alarm',
      }),
    );

    await Alarm.set(
      alarmSettings: settings,
    );
  }

  static bool _isMedicineAlarm(
    AlarmSettings alarm,
  ) {
    final payload = alarm.payload;

    if (payload == null || payload.isEmpty) {
      return false;
    }

    try {
      final decoded = jsonDecode(payload);

      return decoded is Map &&
          decoded['type'] == _payloadType;
    } catch (_) {
      return false;
    }
  }

  static _ParsedTime? _parseTime(
    String scheduledTime,
  ) {
    final parts = scheduledTime.trim().split(':');

    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return _ParsedTime(
      hour: hour,
      minute: minute,
    );
  }

  static String _createNotificationBody(
    List<Medicine> medicines,
  ) {
    if (medicines.length == 1) {
      final medicine = medicines.first;

      return 'Tomar ${medicine.name} '
          '(${medicine.dosage}) • '
          'Gaveta ${medicine.compartment}.';
    }

    final displayedNames = medicines
        .take(3)
        .map((medicine) => medicine.name)
        .join(', ');

    final remaining = medicines.length - 3;

    if (remaining > 0) {
      return '${medicines.length} remédios: '
          '$displayedNames e mais $remaining.';
    }

    return '${medicines.length} remédios: '
        '$displayedNames.';
  }

  /// Cria um número positivo e estável a partir do medicamento
  /// e da data do alarme.
  static int _createStableId(
    String source,
  ) {
    int hash = 0x811C9DC5;

    for (final codeUnit in source.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }

    if (hash == 0) {
      return 1;
    }

    return hash;
  }
}

class _MedicineAlarmGroup {
  final DateTime dateTime;
  final List<Medicine> medicines = [];

  _MedicineAlarmGroup({
    required this.dateTime,
  });
}

class _ParsedTime {
  final int hour;
  final int minute;

  const _ParsedTime({
    required this.hour,
    required this.minute,
  });
}