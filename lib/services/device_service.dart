import 'package:dio/dio.dart';
import 'api_client.dart';

class DeviceService {
  final Dio _dio = ApiClient().dio;

  Future<void> bindDevice(String deviceId) async {
    try {
      await _dio.post(
        '/api/v1/devices/bind',
        data: {'device_id': deviceId},
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>?> getPairedDevice() async {
    try {
      final response = await _dio.get('/api/v1/devices/me');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      return null;
    }
  }

  String _getErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    if (e.response?.statusCode == 404) {
      return 'Dispositivo não encontrado ou já pareado.';
    }
    return 'Erro ao parear o dispositivo.';
  }
}
