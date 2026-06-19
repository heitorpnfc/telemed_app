class Medicine {
  final String id;
  final String name;
  final String dosage;
  final int compartment;
  final String time;
  final List<int> weekDays;
  final String notes;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.compartment,
    required this.time,
    required this.weekDays,
    required this.notes,
  });
}