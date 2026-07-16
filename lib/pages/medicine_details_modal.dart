import 'package:flutter/material.dart';
import '../models/medicine.dart';

class MedicineDetailsModal extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicineDetailsModal({
    super.key,
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required Medicine medicine,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicineDetailsModal(
        medicine: medicine,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Todos os dias';
    final dayNames = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  '${medicine.compartment}',
                  style: const TextStyle(
                    color: Color(0xFF0A6CFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medicine.dosage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildInfoRow(
            icon: Icons.access_time_filled,
            title: 'Horário',
            value: medicine.scheduledTime,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.calendar_month,
            title: 'Dias da Semana',
            value: _formatDays(medicine.weekDays),
          ),
          if (medicine.notes != null && medicine.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.notes,
              title: 'Observações',
              value: medicine.notes!,
            ),
          ],
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Fecha o modal
                    onEdit(); // Abre tela de edição
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Fecha o modal
                    onDelete(); // Aciona lógica de deletar
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Excluir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF9CA3AF), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
