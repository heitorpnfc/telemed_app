import 'package:flutter/material.dart';

import '../models/day_status.dart';

class WeekStatusBar extends StatelessWidget {
  final List<DayStatusData> days;

  const WeekStatusBar({
    super.key,
    required this.days,
  });

  String _dayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'Seg';
      case 2:
        return 'Ter';
      case 3:
        return 'Qua';
      case 4:
        return 'Qui';
      case 5:
        return 'Sex';
      case 6:
        return 'Sáb';
      case 7:
        return 'Dom';
      default:
        return '';
    }
  }

  String _statusText(DaySituation situation) {
    switch (situation) {
      case DaySituation.neutral:
        return 'Sem registro';
      case DaySituation.onTime:
        return 'No horário';
      case DaySituation.warning:
        return 'Atraso leve';
      case DaySituation.late:
        return 'Atrasado';
    }
  }

  Color _statusColor(DaySituation situation) {
    switch (situation) {
      case DaySituation.neutral:
        return const Color(0xFF9CA3AF);
      case DaySituation.onTime:
        return const Color(0xFF22C55E);
      case DaySituation.warning:
        return const Color(0xFFF59E0B);
      case DaySituation.late:
        return const Color(0xFFEF4444);
    }
  }

  void _showDetails(BuildContext context, DayStatusData day) {
    final color = _statusColor(day.situation);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.calendar_month,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_dayLabel(day.weekday)} - ${_statusText(day.situation)}',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (day.details.isEmpty)
                  const Text(
                    'Nenhuma ocorrência registrada para este dia.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
                  )
                else
                  ...day.details.map(
                    (item) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.medicineName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Horário previsto: ${item.scheduledTime}'),
                          Text('Abertura: ${item.openedAt ?? "Não abriu"}'),
                          const SizedBox(height: 6),
                          Text(
                            item.description,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final color = _statusColor(day.situation);

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showDetails(context, day),
            child: Container(
              width: 67,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.13),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: color,
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _dayLabel(day.weekday),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}