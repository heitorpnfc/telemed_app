import 'package:flutter/material.dart';

import '../models/medicine.dart';

class BoxPage extends StatelessWidget {
  final List<Medicine> medicines;

  const BoxPage({
    super.key,
    required this.medicines,
  });

  static const List<String> _weekDays = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  List<Medicine> _medicinesForCompartment(int compartment) {
    final filtered = medicines
        .where(
          (medicine) => medicine.compartment == compartment,
        )
        .toList();

    filtered.sort(
      (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
    );

    return filtered;
  }

  String _medicineQuantityText(int quantity) {
    if (quantity == 0) {
      return 'Nenhum medicamento';
    }

    if (quantity == 1) {
      return '1 medicamento';
    }

    return '$quantity medicamentos';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Caixa de remédios'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final compartment = index + 1;
          final weekDay = _weekDays[index];

          final compartmentMedicines =
              _medicinesForCompartment(compartment);

          return _CompartmentCard(
            compartment: compartment,
            weekDay: weekDay,
            medicines: compartmentMedicines,
            quantityText: _medicineQuantityText(
              compartmentMedicines.length,
            ),
          );
        },
      ),
    );
  }
}

class _CompartmentCard extends StatelessWidget {
  final int compartment;
  final String weekDay;
  final List<Medicine> medicines;
  final String quantityText;

  const _CompartmentCard({
    required this.compartment,
    required this.weekDay,
    required this.medicines,
    required this.quantityText,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEmpty = medicines.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE1E7EF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$compartment',
                  style: const TextStyle(
                    color: Color(0xFF0A6CFF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compartimento $compartment',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      weekDay,
                      style: const TextStyle(
                        color: Color(0xFF0A6CFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isEmpty
                      ? const Color(0xFFF3F4F6)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  medicines.length.toString(),
                  style: TextStyle(
                    color: isEmpty
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF047857),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isEmpty
                  ? const Color(0xFFF7F8FA)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  isEmpty
                      ? Icons.inventory_2_outlined
                      : Icons.medication_outlined,
                  color: isEmpty
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF059669),
                ),
                const SizedBox(width: 10),
                Text(
                  quantityText,
                  style: TextStyle(
                    color: isEmpty
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF047857),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          if (medicines.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            ...medicines.map(
              (medicine) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MedicineItem(
                  medicine: medicine,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MedicineItem extends StatelessWidget {
  final Medicine medicine;

  const _MedicineItem({
    required this.medicine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              medicine.scheduledTime,
              style: const TextStyle(
                color: Color(0xFF0A6CFF),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  medicine.dosage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9CA3AF),
          ),
        ],
      ),
    );
  }
}