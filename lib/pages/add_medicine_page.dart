import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/medicine.dart';
import '../services/medicine_service.dart';

class AddMedicinePage extends StatefulWidget {
  final Medicine? medicine;
  const AddMedicinePage({super.key, this.medicine});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  String _currentName = '';
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  int _selectedCompartment = 1;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  final List<int> _selectedDays = [];
  List<String> _medicineOptions = [];
  bool _isLoading = false;

  final List<String> _dayNames = [
    'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom',
  ];

  @override
  void initState() {
    super.initState();
    _loadBulario();
    
    if (widget.medicine != null) {
      _currentName = widget.medicine!.name;
      _dosageController.text = widget.medicine!.dosage;
      _notesController.text = widget.medicine!.notes ?? '';
      _selectedCompartment = widget.medicine!.compartment;
      final parts = widget.medicine!.scheduledTime.split(':');
      if (parts.length >= 2) {
        _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      _selectedDays.addAll(widget.medicine!.weekDays);
    }
  }

  Future<void> _loadBulario() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/bulario_brasil.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        _medicineOptions = jsonList.cast<String>();
      });
    } catch (e) {
      debugPrint('Erro ao carregar bulário: $e');
    }
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (result != null) {
      setState(() {
        _selectedTime = result;
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _save() async {
    if (_currentName.trim().isEmpty) {
      _showError('Informe o nome do remédio.');
      return;
    }
    if (_dosageController.text.trim().isEmpty) {
      _showError('Informe a dosagem.');
      return;
    }
    if (_selectedDays.isEmpty) {
      _showError('Selecione pelo menos um dia da semana.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final medicine = Medicine(
        id: widget.medicine?.id ?? '', 
        name: _currentName.trim(),
        dosage: _dosageController.text.trim(),
        compartment: _selectedCompartment,
        scheduledTime: _formatTime(_selectedTime),
        weekDays: List.from(_selectedDays)..sort(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      final savedMedicine = widget.medicine == null
          ? await MedicineService().createMedicine(medicine)
          : await MedicineService().updateMedicine(medicine);

      if (!mounted) return;
      Navigator.pop(context, savedMedicine);
    } catch (e) {
      _showError(e.toString());
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
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

  Widget _buildDayChip(int index) {
    final day = index + 1;
    final selected = _selectedDays.contains(day);
    return FilterChip(
      label: Text(_dayNames[index]),
      selected: selected,
      selectedColor: const Color(0xFFDBEAFE),
      checkmarkColor: const Color(0xFF0A6CFF),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF0A6CFF) : const Color(0xFF374151),
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => _toggleDay(day),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = _formatTime(_selectedTime);
    final isEditing = widget.medicine != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar remédio' : 'Adicionar remédio'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
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
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _currentName),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    _currentName = textEditingValue.text;
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _medicineOptions.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _currentName = selection;
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          height: 200.0,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return ListTile(
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: (val) => _currentName = val,
                      decoration: const InputDecoration(
                        labelText: 'Nome do remédio',
                        hintText: 'Pesquise ou digite o nome',
                        prefixIcon: Icon(Icons.medication_outlined),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosagem',
                    hintText: 'Ex: 500 mg, 1 comprimido, 20 gotas',
                    prefixIcon: Icon(Icons.science_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: _selectedCompartment,
                  decoration: const InputDecoration(
                    labelText: 'Compartimento da caixa',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: List.generate(
                    7,
                    (index) {
                      final compartment = index + 1;
                      return DropdownMenuItem(
                        value: compartment,
                        child: Text('Compartimento $compartment'),
                      );
                    },
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCompartment = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _pickTime,
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
          const Text(
            'Dias da semana',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              7,
              _buildDayChip,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Observações (Opcional)',
              hintText: 'Ex: tomar após o café',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? 'Salvar alterações' : 'Salvar remédio'),
                ),
        ],
      ),
    );
  }
}
