import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bula.dart';

class BulaService {
  final String baseUrl = 'https://bula.vercel.app';

  Future<List<Bula>> pesquisarMedicamento(String nome) async {
    if (nome.isEmpty) return [];

    final url = Uri.parse('$baseUrl/pesquisar?nome=$nome&pagina=1');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> resultados = data['content'] ?? [];
        
        return resultados.map((json) => Bula.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar dados da ANVISA');
      }
    } catch (e) {
      print('===ERRO===: $e');
      throw Exception('Falha na ligação à internet');
    }
  }

  String obterUrlPdf(String idBula) {
    return '$baseUrl/bula?id=$idBula';
  }
}