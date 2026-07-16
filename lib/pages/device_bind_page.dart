import 'package:flutter/material.dart';
import '../services/device_service.dart';

class DeviceBindPage extends StatefulWidget {
  const DeviceBindPage({super.key});

  @override
  State<DeviceBindPage> createState() => _DeviceBindPageState();
}

class _DeviceBindPageState extends State<DeviceBindPage> {
  final _deviceController = TextEditingController();
  bool _isLoading = false;

  Future<void> _bindDevice() async {
    final deviceId = _deviceController.text.trim();
    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe o ID da caixinha.'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await DeviceService().bindDevice(deviceId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caixinha vinculada com sucesso!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _deviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vincular Caixinha IoT'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Color(0xFF0A6CFF),
            ),
            const SizedBox(height: 24),
            const Text(
              'Conecte sua Caixinha Inteligente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Digite o ID localizado na base da sua caixa para sincronizá-la com o seu aplicativo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _deviceController,
              decoration: const InputDecoration(
                labelText: 'ID do Dispositivo (Ex: CX-998877)',
                prefixIcon: Icon(Icons.memory),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const Spacer(),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _bindDevice,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Vincular Agora'),
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
