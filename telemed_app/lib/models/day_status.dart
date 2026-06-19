enum DaySituation {
  neutral,
  onTime,
  warning,
  late,
}

class DelayedMedicineInfo {
  final String medicineName;
  final String scheduledTime;
  final String? openedAt;
  final String description;

  DelayedMedicineInfo({
    required this.medicineName,
    required this.scheduledTime,
    this.openedAt,
    required this.description,
  });
}

class DayStatusData {
  final int weekday;
  final DaySituation situation;
  final List<DelayedMedicineInfo> details;

  DayStatusData({
    required this.weekday,
    required this.situation,
    required this.details,
  });
}