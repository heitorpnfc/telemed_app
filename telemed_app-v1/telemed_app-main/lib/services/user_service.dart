import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class UserService {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!');
    }
    return utf8.decode(base64Url.decode(output));
  }

  Future<String> _getMyUserId() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) throw Exception('Token não encontrado');
    
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Token inválido');
    
    final payload = jsonDecode(_decodeBase64(parts[1]));
    return payload['sub'];
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final myId = await _getMyUserId();
      final response = await _dio.get('/users/$myId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> updateMyProfile(String name) async {
    try {
      final myId = await _getMyUserId();
      final response = await _dio.put(
        '/users/$myId',
        data: {'name': name},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<void> deleteMyAccount() async {
    try {
      final myId = await _getMyUserId();
      await _dio.delete('/users/$myId');
      
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  String _getErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return 'Erro ao processar sua requisição.';
  }
}
