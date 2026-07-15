class ReportUser {
  final String id;
  final String name;
  final String email;

  ReportUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ReportUser.fromJson(Map<String, dynamic> json) {
    return ReportUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

class MedicineStat {
  final String id;
  final String name;
  final String dosage;
  final int compartment;
  final String scheduledTime;
  final List<int> weekDays;
  final int onTimeCount;
  final int lateCount;
  final int warningCount;

  MedicineStat({
    required this.id,
    required this.name,
    required this.dosage,
    required this.compartment,
    required this.scheduledTime,
    required this.weekDays,
    required this.onTimeCount,
    required this.lateCount,
    required this.warningCount,
  });

  factory MedicineStat.fromJson(Map<String, dynamic> json) {
    return MedicineStat(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      compartment: json['compartment'] as int,
      scheduledTime: json['scheduled_time'] as String,
      weekDays: List<int>.from(json['week_days'] ?? []),
      onTimeCount: int.tryParse(json['on_time_count'].toString()) ?? 0,
      lateCount: int.tryParse(json['late_count'].toString()) ?? 0,
      warningCount: int.tryParse(json['warning_count'].toString()) ?? 0,
    );
  }
}

class ReportStats {
  final ReportUser user;
  final List<MedicineStat> stats;
  // O array "devices" é retornado pela API, mas ignorado pelo frontend conforme decisão do cliente.

  ReportStats({
    required this.user,
    required this.stats,
  });

  factory ReportStats.fromJson(Map<String, dynamic> json) {
    return ReportStats(
      user: ReportUser.fromJson(json['user'] as Map<String, dynamic>),
      stats: (json['stats'] as List<dynamic>?)
              ?.map((e) => MedicineStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
