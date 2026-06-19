import 'package:flutter/material.dart';

import '../models/medicine.dart';

class BoxPage extends StatelessWidget {
  final List<Medicine> medicines;

  const BoxPage({
    super.key,
    required this.medicines,
  });

  List<Medicine> _medicinesForCompartment(int compartment) {
    final filtered = medicines
        .where((medicine) => medicine.compartment == compartment)
        .toList();

    filtered.sort((a, b) => a.time.compareTo(b.time));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caixa de remédios'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        itemCount: 7,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 200,
        ),
        itemBuilder: (context, index) {
          final compartment = index + 1;
          final compartmentMedicines =
              _medicinesForCompartment(compartment);

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        '$compartment',
                        style: const TextStyle(
                          color: Color(0xFF0A6CFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Compartimento $compartment',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (compartmentMedicines.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Vazio',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: compartmentMedicines.map(
                        (medicine) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${medicine.time} - ${medicine.name}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}