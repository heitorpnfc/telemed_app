import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/device_service.dart';

class DeviceBindPage extends StatefulWidget {
  const DeviceBindPage({super.key});

  @override
  State<DeviceBindPage> createState() => _DeviceBindPageState();
}

class _DeviceBindPageState extends State<DeviceBindPage> {
  final TextEditingController _deviceController = TextEditingController();

  bool _isLoading = false;

  Future<void> _bindDevice() async {
    if (_isLoading) return;

    final String deviceId =
        _deviceController.text.trim().toUpperCase();

    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, informe ou escaneie o ID da caixinha.',
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
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

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _scanQrCode() async {
    if (_isLoading) return;

    final String? scannedValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const DeviceQrScannerPage(),
      ),
    );

    if (!mounted || scannedValue == null) return;

    final String deviceId = scannedValue.trim().toUpperCase();

    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O QR Code não contém um ID válido.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Coloca o código lido no campo.
    _deviceController.text = deviceId;

    // Vincula automaticamente após a leitura.
    await _bindDevice();
  }

  @override
  void dispose() {
    _deviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Vincular Caixinha IoT',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      const Icon(
                        Icons.qr_code_scanner,
                        size: 90,
                        color: Color(0xFF0A6CFF),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Conecte sua Caixinha Inteligente',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          height: 1.3,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Escaneie o QR Code localizado na base da sua '
                        'caixinha para sincronizá-la com o aplicativo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),

                      const SizedBox(height: 32),

                      FilledButton.icon(
                        onPressed: _isLoading ? null : _scanQrCode,
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          size: 26,
                        ),
                        label: const Text('Ler QR Code'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0A6CFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 17,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'ou digite o código',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      TextField(
                        controller: _deviceController,
                        enabled: !_isLoading,
                        textCapitalization:
                            TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          _bindDevice();
                        },
                        decoration: InputDecoration(
                          labelText: 'ID do dispositivo',
                          hintText: 'Ex.: RC-AF5996',
                          prefixIcon: const Icon(Icons.memory),
                          suffixIcon: IconButton(
                            tooltip: 'Ler QR Code',
                            onPressed:
                                _isLoading ? null : _scanQrCode,
                            icon: const Icon(
                              Icons.qr_code_scanner,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFFD1D5DB),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                FilledButton(
                  onPressed: _bindDevice,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F67A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 17,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Vincular Agora'),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tela que abre a câmera e realiza a leitura do QR Code.
class DeviceQrScannerPage extends StatefulWidget {
  const DeviceQrScannerPage({super.key});

  @override
  State<DeviceQrScannerPage> createState() =>
      _DeviceQrScannerPageState();
}

class _DeviceQrScannerPageState
    extends State<DeviceQrScannerPage> {
  bool _codeProcessed = false;

  void _handleQrCode(BarcodeCapture capture) {
    if (_codeProcessed || !mounted) return;

    for (final Barcode barcode in capture.barcodes) {
      final String? value = barcode.rawValue?.trim();

      if (value == null || value.isEmpty) {
        continue;
      }

      // Impede que a câmera leia o mesmo QR Code várias vezes.
      _codeProcessed = true;

      Navigator.pop(context, value);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Escanear QR Code',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: _handleQrCode,
          ),

          Center(
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: const Color(0xFF0A6CFF),
                  width: 5,
                ),
              ),
            ),
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 0, 0, 0.70),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Posicione o QR Code da caixinha dentro do quadrado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}