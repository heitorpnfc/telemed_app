import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../services/medicine_service.dart';
import '../models/bula.dart'; // <-- Importando o Model da Bula
import '../services/bula_service.dart'; // <-- Importando o Service da Bula

class AddMedicinePage extends StatefulWidget {
  const AddMedicinePage({super.key});

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  // Instância do serviço que busca as bulas
  final BulaService _bulaService = BulaService();
  
  // O Autocomplete gerencia o próprio controller, então salvamos a referência dele aqui
  TextEditingController? _nomeRemedioController;
  
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  int _selectedCompartment = 1;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  final List<int> _selectedDays = [];

  final List<String> _dayNames = [
    'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom',
  ];

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

  bool _isLoading = false;

  Future<void> _save() async {
    // Pega o texto do controller do Autocomplete
    final nomeRemedio = _nomeRemedioController?.text.trim() ?? '';

    if (nomeRemedio.isEmpty) {
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
        id: '',
        name: nomeRemedio, // Usando o nome buscado
        dosage: _dosageController.text.trim(),
        compartment: _selectedCompartment,
        scheduledTime: _formatTime(_selectedTime),
        weekDays: List.from(_selectedDays)..sort(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      final createdMedicine = await MedicineService().createMedicine(medicine);

      if (!mounted) return;
      Navigator.pop(context, createdMedicine);
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
    // Não damos dispose no _nomeRemedioController pois o Autocomplete gerencia isso internamente
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar remédio'),
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
                
                // --- CAMPO DE AUTOCOMPLETAR (BULÁRIO ANVISA) ---
                Autocomplete<Bula>(
                  displayStringForOption: (Bula option) => option.nomeProduto,
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    // Começa a buscar na API apenas após 3 letras digitadas para economizar dados
                    if (textEditingValue.text.length < 3) {
                      return const Iterable<Bula>.empty();
                    }
                    try {
                      return await _bulaService.pesquisarMedicamento(textEditingValue.text);
                    } catch (e) {
                      return const Iterable<Bula>.empty();
                    }
                  },
                  onSelected: (Bula selecao) {
                    // Quando escolhe o remédio, preenchemos o campo de observações com a bula!
                    setState(() {
                      String infoExtra = 'Fabricante: ${selecao.razaoSocial}';
                      
                      if (selecao.idBulaPacienteProtegido != null) {
                        final linkBula = _bulaService.obterUrlPdf(selecao.idBulaPacienteProtegido!);
                        infoExtra += '\nBula: $linkBula';
                      }

                      // Concatena com o que já estiver escrito nas observações
                      if (_notesController.text.isEmpty) {
                        _notesController.text = infoExtra;
                      } else {
                        _notesController.text = '${_notesController.text}\n\n$infoExtra';
                      }
                    });

                    // Mostra um aviso verde de sucesso
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${selecao.nomeProduto} importado!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    // Guarda o controller criado pelo Autocomplete para usarmos no _save()
                    _nomeRemedioController = textEditingController;

                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Nome do remédio',
                        hintText: 'Digite para buscar na ANVISA...',
                        prefixIcon: Icon(Icons.medication_outlined),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    // O design da caixinha de sugestões flutuante
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          // Ajusta a largura da lista para encaixar no seu layout
                          width: MediaQuery.of(context).size.width - 68, 
                          height: 250,
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (BuildContext context, int index) {
                              final Bula option = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(Icons.search, color: Color(0xFF0A6CFF)),
                                title: Text(
                                  option.nomeProduto, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  option.razaoSocial,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // ------------------------------------------------
                
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
              labelText: 'Observações',
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
                  label: const Text('Salvar remédio'),
                ),
        ],
      ),
    );
  }
}