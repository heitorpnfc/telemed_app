import 'package:flutter/material.dart';

import '../models/day_status.dart';
import '../models/medicine.dart';
import '../services/auth_service.dart';
import '../widgets/week_status_bar.dart';
import 'add_medicine_page.dart';
import 'box_page.dart';
import 'login_page.dart';
import 'weekly_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Medicine> _medicines = [];

  final List<DayStatusData> _weekStatus = [
    DayStatusData(
      weekday: 1,
      situation: DaySituation.onTime,
      details: [
        DelayedMedicineInfo(
          medicineName: 'Losartana',
          scheduledTime: '08:00',
          openedAt: '08:04',
          description: 'Compartimento aberto dentro do horário esperado.',
        ),
      ],
    ),
    DayStatusData(
      weekday: 2,
      situation: DaySituation.warning,
      details: [
        DelayedMedicineInfo(
          medicineName: 'Dipirona',
          scheduledTime: '14:00',
          openedAt: '14:22',
          description:
              'O compartimento foi aberto após a tolerância de 15 minutos.',
        ),
      ],
    ),
    DayStatusData(
      weekday: 3,
      situation: DaySituation.late,
      details: [
        DelayedMedicineInfo(
          medicineName: 'Vitamina D',
          scheduledTime: '09:00',
          openedAt: null,
          description:
              'O compartimento não foi aberto dentro do período esperado.',
        ),
      ],
    ),
    DayStatusData(
      weekday: 4,
      situation: DaySituation.onTime,
      details: [
        DelayedMedicineInfo(
          medicineName: 'Omeprazol',
          scheduledTime: '07:00',
          openedAt: '07:03',
          description: 'Remédio tomado no horário correto.',
        ),
      ],
    ),
    DayStatusData(
      weekday: 5,
      situation: DaySituation.neutral,
      details: [],
    ),
    DayStatusData(
      weekday: 6,
      situation: DaySituation.warning,
      details: [
        DelayedMedicineInfo(
          medicineName: 'Metformina',
          scheduledTime: '20:00',
          openedAt: '20:30',
          description: 'O remédio foi tomado com atraso moderado.',
        ),
      ],
    ),
    DayStatusData(
      weekday: 7,
      situation: DaySituation.late,
      details: [
        DelayedMedicineInfo(
          medicineName: 'Captopril',
          scheduledTime: '18:00',
          openedAt: '19:15',
          description:
              'O compartimento foi aberto com mais de 1 hora de atraso.',
        ),
      ],
    ),
  ];

  Medicine? get _nextMedicine {
    final today = DateTime.now().weekday;

    final todayMedicines = _medicines
        .where((medicine) => medicine.weekDays.contains(today))
        .toList();

    todayMedicines.sort((a, b) => a.time.compareTo(b.time));

    if (todayMedicines.isEmpty) return null;

    return todayMedicines.first;
  }

  Future<void> _addMedicine() async {
    final result = await Navigator.push<Medicine>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddMedicinePage(),
      ),
    );

    if (result != null) {
      setState(() {
        _medicines.add(result);
      });
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A6CFF),
            Color(0xFF22C55E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A6CFF).withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, usuário 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Seu cuidado está em dia?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextMedicineCard() {
    final nextMedicine = _nextMedicine;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: nextMedicine == null
          ? const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.medication_outlined,
                    color: Color(0xFF0A6CFF),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próximo remédio',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Nenhum remédio cadastrado para hoje.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    '${nextMedicine.compartment}',
                    style: const TextStyle(
                      color: Color(0xFF0A6CFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Próximo remédio',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextMedicine.name,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${nextMedicine.dosage} • ${nextMedicine.time} • Compartimento ${nextMedicine.compartment}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEFF6FF),
              child: Icon(
                icon,
                color: const Color(0xFF0A6CFF),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicinesList() {
    if (_medicines.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Text(
          'Nenhum remédio cadastrado ainda. Clique em “Adicionar remédio” para começar.',
          style: TextStyle(
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    return Column(
      children: _medicines.map((medicine) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  '${medicine.compartment}',
                  style: const TextStyle(
                    color: Color(0xFF0A6CFF),
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
                      medicine.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${medicine.dosage} • ${medicine.time}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _medicines.remove(medicine);
                  });
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMedicine,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
      appBar: AppBar(
        title: const Text('RemindCare'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 22),
          const Text(
            'Resumo da semana',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          WeekStatusBar(days: _weekStatus),
          const SizedBox(height: 22),
          _buildNextMedicineCard(),
          const SizedBox(height: 22),
          _buildActionButton(
            icon: Icons.medication_outlined,
            title: 'Adicionar remédio',
            subtitle: 'Cadastre nome, dose, horário e compartimento.',
            onTap: _addMedicine,
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.calendar_month_outlined,
            title: 'Ver semana',
            subtitle: 'Veja quais remédios estão marcados em cada dia.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WeeklyPage(
                    medicines: _medicines,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.inventory_2_outlined,
            title: 'Ver caixa',
            subtitle: 'Confira quais remédios estão em cada compartimento.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BoxPage(
                    medicines: _medicines,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 26),
          const Text(
            'Remédios cadastrados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildMedicinesList(),
        ],
      ),
    );
  }
}