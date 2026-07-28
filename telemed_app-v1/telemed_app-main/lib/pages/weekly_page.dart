import 'package:flutter/material.dart';

import '../models/medicine.dart';

class WeeklyPage extends StatelessWidget {
  final List<Medicine> medicines;

  const WeeklyPage({
    super.key,
    required this.medicines,
  });

  static const List<String> dayNames = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  List<Medicine> _medicinesForDay(int day) {
    final filtered = medicines
        .where((medicine) => medicine.weekDays.contains(day))
        .toList();

    filtered.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remédios da semana'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = index + 1;
          final dayMedicines = _medicinesForDay(day);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
              clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 6,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
              title: Text(
                dayNames[index],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              subtitle: Text(
                dayMedicines.isEmpty
                    ? 'Nenhum remédio'
                    : '${dayMedicines.length} remédio(s)',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
              children: dayMedicines.isEmpty
                  ? [
                      const ListTile(
                        title: Text(
                          'Nenhum remédio cadastrado para este dia.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      )
                    ]
                  : dayMedicines.map((medicine) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEFF6FF),
                            child: Text(
                              '${medicine.compartment}',
                              style: const TextStyle(
                                color: Color(0xFF0A6CFF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            medicine.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${medicine.dosage} • ${medicine.scheduledTime}',
                          ),
                        ),
                       ),
                      );
                    }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}