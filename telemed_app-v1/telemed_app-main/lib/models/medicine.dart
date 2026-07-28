class Medicine {
  final String id;
  final String name;
  final String dosage;
  final int compartment;
  final String scheduledTime;
  final List<int> weekDays;
  final String? notes;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.compartment,
    required this.scheduledTime,
    required this.weekDays,
    this.notes,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      compartment: json['compartment'] as int,
      scheduledTime: json['scheduled_time'] as String,
      weekDays: List<int>.from(json['week_days'] ?? []),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'compartment': compartment,
      'scheduled_time': scheduledTime,
      'week_days': weekDays,
      'notes': notes,
    };
  }
}