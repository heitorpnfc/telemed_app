import 'package:flutter/material.dart';
import '../services/medicine_service.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  bool _isLoading = true;
  List<dynamic> _logs = [];
  Map<String, String> _medicineNames = {};

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final futures = await Future.wait([
        MedicineService().getMedicines(),
        MedicineService().getMedicineLogs(),
      ]);
      final List<dynamic> medicines = futures[0];
      final List<dynamic> logs = futures[1];

      final Map<String, String> namesMap = {};
      for (var med in medicines) {
        namesMap[med.id] = med.name;
      }

      if (mounted) {
        setState(() {
          _medicineNames = namesMap;
          _logs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar histórico: $e')),
        );
      }
    }
  }

  Future<void> _registerManual() async {
    // Busca a lista de remédios para o usuário escolher qual tomou
    List<dynamic> medicines = [];
    try {
      medicines = await MedicineService().getMedicines();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar medicamentos.')),
        );
      }
      return;
    }

    if (medicines.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum medicamento cadastrado.')),
        );
      }
      return;
    }

    if (!mounted) return;
    
    // Mostra um bottom sheet para selecionar o remédio
    final selectedMedicineId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Qual remédio você tomou?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final med = medicines[index];
                      return ListTile(
                        leading: const Icon(Icons.medication, color: Color(0xFF0A6CFF)),
                        title: Text(med.name),
                        subtitle: Text(med.scheduledTime),
                        onTap: () {
                          Navigator.pop(context, med.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );

    if (selectedMedicineId != null) {
      final String? situation = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Como classifica essa dose?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                title: const Text('No horário'),
                onTap: () => Navigator.pop(context, 'onTime'),
              ),
              ListTile(
                leading: const Icon(Icons.warning, color: Color(0xFFF59E0B)),
                title: const Text('Com pequeno atraso'),
                onTap: () => Navigator.pop(context, 'warning'),
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Color(0xFFEF4444)),
                title: const Text('Atrasado / Esquecido'),
                onTap: () => Navigator.pop(context, 'late'),
              ),
            ],
          ),
        ),
      );

      if (situation != null) {
        try {
          await MedicineService().registerManualLog(selectedMedicineId, situation);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Uso registrado com sucesso!'), backgroundColor: Color(0xFF22C55E)),
            );
          }
          _loadLogs();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao registrar: $e'), backgroundColor: const Color(0xFFEF4444)),
            );
          }
        }
      }
    }
  }

  IconData _getIconForSituation(String situation) {
    switch (situation) {
      case 'onTime':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'late':
      case 'missed':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getColorForSituation(String situation) {
    switch (situation) {
      case 'onTime':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'late':
      case 'missed':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _translateSituation(String situation) {
    switch (situation) {
      case 'onTime':
        return 'No horário';
      case 'warning':
        return 'Com atraso aceitável';
      case 'late':
        return 'Atrasado';
      case 'missed':
        return 'Esquecido';
      default:
        return situation;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico Diário'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _registerManual,
        icon: const Icon(Icons.touch_app),
        label: const Text('Tomei fora de casa'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum remédio tomado hoje ainda.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final String medId = log['medicine_id'] ?? '';
                    final String medName = _medicineNames[medId] ?? log['medicine_name'] ?? 'Remédio Desconhecido';
                    final String time = log['opened_at'] != null 
                        ? DateTime.tryParse(log['opened_at'])?.toLocal().toString().split(' ')[1].substring(0, 5) ?? '--:--'
                        : '--:--';
                    final String situation = log['situation'] ?? 'unknown';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: _getColorForSituation(situation).withOpacity(0.1),
                          child: Icon(
                            _getIconForSituation(situation),
                            color: _getColorForSituation(situation),
                          ),
                        ),
                        title: Text(
                          medName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(_translateSituation(situation)),
                        trailing: Text(
                          time,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6B7280)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
