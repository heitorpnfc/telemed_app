import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medicine.dart';
import '../services/medicine_service.dart';
import '../pages/bulario_page.dart'; 

class AddMedicinePage extends StatefulWidget {
  final Medicine? medicine;

  const AddMedicinePage({
    super.key,
    this.medicine,
  });

  @override
  State<AddMedicinePage> createState() =>
      _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  String _currentName = '';
  // NOVO: Guarda a URL do PDF atual
  String? _currentPdfUrl; 

  final TextEditingController _dosageController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  TimeOfDay _selectedTime = const TimeOfDay(
    hour: 8,
    minute: 0,
  );

  // NOVO: Agora a lista guarda Mapas para conter tanto o Nome quanto a URL
  List<Map<String, String>> _medicineOptions = [];

  bool _isLoading = false;

  int _selectedWeekday = DateTime.sunday;

  static const List<int> _weekdayOrder = [
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ];

  static const Map<int, String> _weekdayNames = {
    DateTime.sunday: 'Domingo',
    DateTime.monday: 'Segunda-feira',
    DateTime.tuesday: 'Terça-feira',
    DateTime.wednesday: 'Quarta-feira',
    DateTime.thursday: 'Quinta-feira',
    DateTime.friday: 'Sexta-feira',
    DateTime.saturday: 'Sábado',
  };

  static const Map<int, int> _weekdayToCompartment = {
    DateTime.sunday: 1,
    DateTime.monday: 2,
    DateTime.tuesday: 3,
    DateTime.wednesday: 4,
    DateTime.thursday: 5,
    DateTime.friday: 6,
    DateTime.saturday: 7,
  };

  static const Map<int, int> _compartmentToWeekday = {
    1: DateTime.sunday,
    2: DateTime.monday,
    3: DateTime.tuesday,
    4: DateTime.wednesday,
    5: DateTime.thursday,
    6: DateTime.friday,
    7: DateTime.saturday,
  };

  int get _selectedCompartment =>
      _weekdayToCompartment[_selectedWeekday]!;

  @override
  void initState() {
    super.initState();

    _loadBulario();

    final medicine = widget.medicine;

    if (medicine != null) {
      _currentName = medicine.name;
      _dosageController.text = medicine.dosage;
      _notesController.text = medicine.notes ?? '';

      if (medicine.weekDays.isNotEmpty &&
          medicine.weekDays.first >= DateTime.monday &&
          medicine.weekDays.first <= DateTime.sunday) {
        _selectedWeekday = medicine.weekDays.first;
      } else {
        _selectedWeekday =
            _compartmentToWeekday[medicine.compartment] ??
                DateTime.sunday;
      }

      final parts = medicine.scheduledTime.split(':');

      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);

        if (hour != null &&
            minute != null &&
            hour >= 0 &&
            hour <= 23 &&
            minute >= 0 &&
            minute <= 59) {
          _selectedTime = TimeOfDay(
            hour: hour,
            minute: minute,
          );
        }
      }
    }
  }

  Future<void> _loadBulario() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/bulario_brasil.json',
      );

      final jsonList = jsonDecode(jsonString) as List<dynamic>;

      if (!mounted) return;

      setState(() {
        // NOVO: Lê o JSON aceitando strings antigas ou os novos objetos com url
        _medicineOptions = jsonList.map((item) {
          if (item is String) {
            return {'nome': item, 'url': ''};
          } else if (item is Map) {
            return {
              'nome': item['nome']?.toString() ?? '',
              'url': item['url']?.toString() ?? '',
            };
          }
          return {'nome': '', 'url': ''};
        }).where((m) => m['nome']!.isNotEmpty).toList();
      });
    } catch (error) {
      debugPrint(
        'Erro ao carregar bulário: $error',
      );
    }
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedTime = result;
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> _save() async {
    final medicineName = _currentName.trim();
    final dosage = _dosageController.text.trim();
    final notes = _notesController.text.trim();

    if (medicineName.isEmpty) {
      _showError('Informe o nome do remédio.');
      return;
    }

    if (dosage.isEmpty) {
      _showError('Informe a dosagem.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final medicine = Medicine(
        id: widget.medicine?.id ?? '',
        name: medicineName,
        dosage: dosage,
        compartment: _selectedCompartment,
        scheduledTime: _formatTime(_selectedTime),
        weekDays: [_selectedWeekday],
        notes: notes.isEmpty ? null : notes,
      );

      final savedMedicine = widget.medicine == null
          ? await MedicineService().createMedicine(medicine)
          : await MedicineService().updateMedicine(medicine);

      if (!mounted) return;

      Navigator.pop(
        context,
        savedMedicine,
      );
    } catch (error) {
      if (!mounted) return;

      _showError(
        error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTime(_selectedTime);
    final isEditing = widget.medicine != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Editar remédio'
              : 'Adicionar remédio',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          28,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              children: [
                // NOVO: Autocomplete agora funciona com Map<String, String>
                Autocomplete<Map<String, String>>(
                  initialValue: TextEditingValue(
                    text: _currentName,
                  ),
                  displayStringForOption: (option) => option['nome']!,
                  optionsBuilder: (
                    TextEditingValue textEditingValue,
                  ) {
                    final search =
                        textEditingValue.text.trim();

                    if (search.isEmpty) {
                      return const Iterable<Map<String, String>>.empty();
                    }

                    return _medicineOptions.where(
                      (option) => option['nome']!
                          .toLowerCase()
                          .contains(search.toLowerCase()),
                    );
                  },
                  onSelected: (selection) {
                    setState(() {
                      _currentName = selection['nome']!;
                      // NOVO: Salva a URL se ela existir
                      _currentPdfUrl = selection['url']!.isNotEmpty 
                          ? selection['url'] 
                          : null;
                    });
                  },
                  optionsViewBuilder: (
                    context,
                    onSelected,
                    options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius:
                            BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          width:
                              MediaQuery.sizeOf(context).width -
                                  32,
                          height: 200,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (
                              context,
                              index,
                            ) {
                              final option =
                                  options.elementAt(index);
                              final hasPdf = option['url']!.isNotEmpty;

                              return ListTile(
                                title: Text(option['nome']!),
                                // NOVO: Mostra um ícone na lista se o remédio tiver bula
                                trailing: hasPdf 
                                    ? const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20)
                                    : null,
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (
                    context,
                    controller,
                    focusNode,
                    onEditingComplete,
                  ) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction:
                          TextInputAction.next,
                      onChanged: (value) {
                        _currentName = value;
                        // NOVO: Se o usuário apagar o nome, reseta o PDF
                        if (value.isEmpty) {
                          setState(() => _currentPdfUrl = null);
                        }
                      },
                      onEditingComplete:
                          onEditingComplete,
                      decoration: InputDecoration(
                        labelText: 'Nome do remédio',
                        hintText:
                            'Pesquise ou digite o nome',
                        prefixIcon: const Icon(
                          Icons.medication_outlined,
                        ),
                        // NOVO: Botão interativo para abrir a bula
                        suffixIcon: _currentPdfUrl != null
                            ? IconButton(
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                tooltip: 'Ver Bula',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BularioPage(pdfUrl: _currentPdfUrl!),
                                    ),
                                  );
                                  debugPrint("Abrindo PDF: $_currentPdfUrl");
                                },
                              )
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _dosageController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Dosagem',
                    hintText:
                        'Ex.: 500 mg, 1 comprimido ou 20 gotas',
                    prefixIcon: Icon(
                      Icons.science_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _selectedWeekday,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Dia da semana',
                    prefixIcon: Icon(
                      Icons.calendar_today_outlined,
                    ),
                  ),
                  items: _weekdayOrder.map(
                    (weekday) {
                      final dayName =
                          _weekdayNames[weekday]!;

                      final compartment =
                          _weekdayToCompartment[weekday]!;

                      return DropdownMenuItem<int>(
                        value: weekday,
                        child: Text(
                          '$dayName — Compartimento $compartment',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value == null) return;

                          setState(() {
                            _selectedWeekday = value;
                          });
                        },
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _isLoading ? null : _pickTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFD9E1EC),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF0A6CFF),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Horário',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            color: Color(0xFF0A6CFF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _notesController,
            enabled: !_isLoading,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Observações (opcional)',
              hintText: 'Ex.: tomar após o café',
              alignLabelWithHint: true,
              prefixIcon: Icon(
                Icons.notes_outlined,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(
                isEditing
                    ? 'Salvar alterações'
                    : 'Salvar remédio',
              ),
            ),
        ],
      ),
    );
  }
}