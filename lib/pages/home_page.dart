import 'package:flutter/material.dart';

import '../models/day_status.dart';
import '../models/medicine.dart';
import '../models/medicine_log.dart';
import '../services/auth_service.dart';
import '../services/medicine_service.dart';
import '../widgets/adherence_dashboard.dart';
import 'add_medicine_page.dart';
import 'device_bind_page.dart';
import 'medicine_details_modal.dart';
import 'timeline_page.dart';
import 'box_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'weekly_page.dart';
import '../services/device_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Medicine> _medicines = [];
  List<MedicineLog> _todayLogs = [];
  Map<String, dynamic>? _pairedDevice;
  bool _isLoading = true;
  int _dashboardKey = 0;
  String _userName = 'usuário';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        MedicineService().getMedicines(),
        MedicineService().getTodayLogs(),
        UserService().getMyProfile(),
        DeviceService().getPairedDevice(),
      ]);
      
      final medicines = futures[0] as List<Medicine>;
      final logs = futures[1] as List<MedicineLog>;
      final profile = futures[2] as Map<String, dynamic>;
      final pairedDevice = futures[3] as Map<String, dynamic>?;

      if (mounted) {
        setState(() {
          _medicines = medicines;
          _todayLogs = logs;
          _userName = profile['name']?.split(' ')[0] ?? 'usuário';
          _pairedDevice = pairedDevice;
          _isLoading = false;
        });
        NotificationService().scheduleMedicineAlarms(medicines);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar remédios: $e')),
        );
      }
    }
  }

  // Comentado conforme pedido para focar apenas nos remédios
  /*
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
  */

  // Método mantido para manter compatibilidade, embora usemos a timeline agora
  Medicine? get _nextMedicine {
    final now = DateTime.now();
    final today = now.weekday; // 1 = Seg, 7 = Dom
    final currentTimeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final todayMedicines = _medicines
        .where((medicine) => medicine.weekDays.contains(today))
        .toList();

    todayMedicines.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    final upcoming = todayMedicines
        .where((m) => m.scheduledTime.compareTo(currentTimeString) > 0)
        .toList();

    if (upcoming.isNotEmpty) return upcoming.first;
    if (todayMedicines.isNotEmpty) return todayMedicines.first;
    return null;
  }

  List<Medicine> get _todayMedicines {
    final now = DateTime.now();
    final today = now.weekday;
    final list = _medicines.where((m) => m.weekDays.contains(today)).toList();
    list.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return list;
  }

  String _calculateLiveStatus(Medicine medicine) {
    // FONTE ÚNICA DA VERDADE: Se a caixa (via DB) mandou um status, confiamos cegamente nela.
    final log = _todayLogs.where((l) => l.medicineId == medicine.id).lastOrNull;
    if (log != null) {
      return log.situation; // 'onTime', 'warning', 'late', 'early', 'missed'
    }

    // Se não há log da caixa, o padrão é 'Pendente' (esperando a caixa agir)
    final now = DateTime.now();
    final parts = medicine.scheduledTime.split(':');
    final schedTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    
    final diffMins = now.difference(schedTime).inMinutes;

    // Apenas um "fallback de segurança": se já passou 1 hora e a caixa falhou 
    // catastroficamente em mandar o evento 'missed' por queda de internet, assumimos Missed.
    if (diffMins > 60) return 'missed';

    // Para todo o resto, aguardamos a caixa tomar a decisão.
    return 'pending';
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
        _dashboardKey++;
      });
      NotificationService().scheduleMedicineAlarms(_medicines);
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $_userName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
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

  Widget _buildTodayTimeline() {
    final todayMeds = _todayMedicines;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Remédios de Hoje',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (todayMeds.isEmpty)
            const Text(
              'Nenhum remédio agendado para hoje.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          else
            ...todayMeds.map((med) {
              final status = _calculateLiveStatus(med);
              
              Color iconColor;
              Color bgColor;
              IconData iconData;
              String statusText;

              switch (status) {
                case 'onTime':
                  iconColor = const Color(0xFF22C55E);
                  bgColor = const Color(0xFFDCFCE7);
                  iconData = Icons.check_circle;
                  statusText = 'Tomado no Horário';
                  break;
                case 'warning':
                  iconColor = const Color(0xFFF59E0B);
                  bgColor = const Color(0xFFFEF3C7);
                  iconData = Icons.warning_rounded;
                  statusText = 'Atrasado';
                  break;
                case 'late':
                  iconColor = const Color(0xFFEA580C);
                  bgColor = const Color(0xFFFFEDD5);
                  iconData = Icons.schedule_outlined;
                  statusText = 'Muito Atrasado';
                  break;
                case 'missed':
                case 'missed_live':
                  iconColor = const Color(0xFFEF4444);
                  bgColor = const Color(0xFFFEE2E2);
                  iconData = Icons.cancel;
                  statusText = 'Esquecido';
                  break;
                case 'take_now':
                  iconColor = const Color(0xFF0A6CFF);
                  bgColor = const Color(0xFFEFF6FF);
                  iconData = Icons.notifications_active;
                  statusText = 'Hora de Tomar!';
                  break;
                case 'early':
                  iconColor = const Color(0xFF8B5CF6);
                  bgColor = const Color(0xFFEDE9FE);
                  iconData = Icons.timer_outlined;
                  statusText = 'Adiantado';
                  break;
                default: // pending
                  iconColor = const Color(0xFF9CA3AF);
                  bgColor = const Color(0xFFF3F4F6);
                  iconData = Icons.access_time_filled;
                  statusText = 'Pendente';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: bgColor,
                      child: Icon(iconData, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${med.scheduledTime} • Gaveta ${med.compartment}',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
                child: InkWell(
                  onTap: () {
                    MedicineDetailsModal.show(
                      context,
                      medicine: medicine,
                      onEdit: () async {
                        final result = await Navigator.push<Medicine>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddMedicinePage(medicine: medicine),
                          ),
                        );
                        if (result != null) {
                          _loadData();
                          setState(() {
                            _dashboardKey++;
                          });
                        }
                      },
                      onDelete: () async {
                        try {
                          await MedicineService().deleteMedicine(medicine.id);
                          _loadData();
                          setState(() {
                            _dashboardKey++;
                          });
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erro ao deletar: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
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
                        '${medicine.dosage} • ${medicine.scheduledTime}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  try {
                    await MedicineService().deleteMedicine(medicine.id);
                    _loadData();
                    setState(() {
                      _dashboardKey++;
                    });
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao deletar: $e')),
                      );
                    }
                  }
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            icon: const Icon(Icons.person),
            tooltip: 'Meu Perfil',
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
          const SizedBox(height: 14),
          AdherenceDashboard(key: ValueKey(_dashboardKey)),
          const SizedBox(height: 24),
          _buildTodayTimeline(),
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
          const SizedBox(height: 10),
          _buildActionButton(
            icon: Icons.history,
            title: 'Histórico de hoje',
            subtitle: 'Veja os horários em que a caixinha foi aberta hoje.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimelinePage()),
              ).then((_) {
                setState(() {
                  _dashboardKey++;
                });
              });
            },
          ),
          const SizedBox(height: 10),
          Builder(builder: (context) {
            if (_pairedDevice != null) {
              final deviceId = _pairedDevice!['id'];
              final lastHb = _pairedDevice!['last_heartbeat_at'];
              bool isOnline = false;
              if (lastHb != null) {
                final hbDate = DateTime.parse(lastHb).toLocal();
                if (DateTime.now().difference(hbDate).inMinutes < 35) {
                  isOnline = true;
                }
              }
              
              return _buildActionButton(
                icon: Icons.qr_code_scanner,
                title: 'Caixa $deviceId',
                subtitle: isOnline ? '🟢 Online (Pareada)' : '🔴 Offline (Verifique Wi-Fi/Bateria)',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeviceBindPage()),
                  );
                },
              );
            } else {
              return _buildActionButton(
                icon: Icons.qr_code_scanner,
                title: 'Parear Caixinha',
                subtitle: 'Conecte sua caixa IoT ao seu perfil.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeviceBindPage()),
                  );
                },
              );
            }
          }),
          const SizedBox(height: 26),
          const Text(
            'Remédios cadastrados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _buildMedicinesList(),
        ],
      ),
    );
  }
}