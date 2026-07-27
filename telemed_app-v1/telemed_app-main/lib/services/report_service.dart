import 'package:dio/dio.dart';
import '../models/report_stats.dart';
import 'api_client.dart';

class ReportService {
  final Dio _dio = ApiClient().dio;

  Future<ReportStats> getStats() async {
    try {
      final response = await _dio.get('/api/v1/reports/stats');
      return ReportStats.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  /// Retorna os bytes do PDF gerado pelo servidor, 
  /// que podem ser salvos localmente ou abertos no dispositivo.
  Future<List<int>> downloadReportDoc() async {
    try {
      final response = await _dio.get(
        '/api/v1/reports/doc',
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );
      
      return response.data as List<int>;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  String _getErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return 'Erro ao carregar os relatórios.';
  }
}
