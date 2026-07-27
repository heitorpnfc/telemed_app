class MedicineLog {
  final String id;
  final String medicineId;
  final String situation;
  final DateTime openedAt;

  MedicineLog({
    required this.id,
    required this.medicineId,
    required this.situation,
    required this.openedAt,
  });

  factory MedicineLog.fromJson(Map<String, dynamic> json) {
    return MedicineLog(
      id: json['id'] as String,
      medicineId: json['medicine_id'] as String,
      situation: json['situation'] as String,
      openedAt: DateTime.parse(json['opened_at'] as String).toLocal(),
    );
  }
}
