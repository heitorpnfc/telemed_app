import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class BularioPage extends StatelessWidget {
  final String pdfUrl;

  const BularioPage({
    super.key,
    required this.pdfUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bula do Medicamento'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        canShowScrollHead: false,
      ),
    );
  }
}