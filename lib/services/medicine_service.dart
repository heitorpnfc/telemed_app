import 'package:dio/dio.dart';
import '../models/medicine.dart';
import 'api_client.dart';

class MedicineService {
  final Dio _dio = ApiClient().dio;

  Future<List<Medicine>> getMedicines() async {
    try {
      final response = await _dio.get('/medicines');
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => Medicine.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<Medicine> createMedicine(Medicine medicine) async {
    try {
      final response = await _dio.post(
        '/medicines',
        data: medicine.toJson()..remove('id'), // O banco de dados gera o UUID
      );
      
      return Medicine.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<void> deleteMedicine(String id) async {
    try {
      await _dio.delete('/medicines/$id');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  String _getErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return 'Erro na comunicação com o servidor.';
  }
}
