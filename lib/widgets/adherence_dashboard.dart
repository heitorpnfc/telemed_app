import 'package:flutter/material.dart';
import '../models/report_stats.dart';
import '../services/report_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:open_filex/open_filex.dart';

class AdherenceDashboard extends StatefulWidget {
  const AdherenceDashboard({super.key});

  @override
  State<AdherenceDashboard> createState() => _AdherenceDashboardState();
}

class _AdherenceDashboardState extends State<AdherenceDashboard> {
  ReportStats? _stats;
  bool _isLoading = true;
  String? _error;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await ReportService().getStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
    });
    try {
      final bytes = await ReportService().downloadReportDoc();
      
      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'relatorio_medico_$timestamp.pdf';

      if (kIsWeb) {
        final base64 = base64Encode(bytes);
        html.AnchorElement(href: 'data:application/pdf;base64,$base64')
          ..setAttribute('download', fileName)
          ..click();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Relatório baixado com sucesso!'),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Relatório baixado com sucesso!'),
              backgroundColor: const Color(0xFF22C55E),
              action: SnackBarAction(
                label: 'Abrir',
                textColor: Colors.white,
                onPressed: () async {
                  await OpenFilex.open(file.path);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao baixar: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Text(
          'Não foi possível carregar as estatísticas.\n$_error',
          style: const TextStyle(color: Color(0xFFEF4444)),
        ),
      );
    }

    if (_stats == null) return const SizedBox.shrink();

    int totalOnTime = 0;
    int totalLate = 0;
    int totalWarning = 0;

    for (var stat in _stats!.stats) {
      totalOnTime += stat.onTimeCount;
      totalLate += stat.lateCount;
      totalWarning += stat.warningCount;
    }

    final totalDoses = totalOnTime + totalLate + totalWarning;
    final double adherenceRate = totalDoses == 0 ? 0 : (totalOnTime / totalDoses) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Visão Geral',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              if (_isDownloading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  onPressed: _downloadPdf,
                  icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF0A6CFF)),
                  tooltip: 'Exportar Relatório PDF',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: totalDoses == 0 ? 0 : adherenceRate / 100,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFFF3F4F6),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        adherenceRate >= 80
                            ? const Color(0xFF22C55E)
                            : adherenceRate >= 50
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444),
                      ),
                    ),
                    Center(
                      child: Text(
                        '${adherenceRate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildStatRow('No horário', totalOnTime, const Color(0xFF22C55E)),
                    const SizedBox(height: 8),
                    _buildStatRow('Atrasado', totalWarning, const Color(0xFFF59E0B)),
                    const SizedBox(height: 8),
                    _buildStatRow('Esquecido', totalLate, const Color(0xFFEF4444)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
