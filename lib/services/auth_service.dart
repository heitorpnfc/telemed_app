import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];

      await _storage.write(
        key: 'access_token',
        value: accessToken,
      );

      await _storage.write(
        key: 'refresh_token',
        value: refreshToken,
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e));
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (refreshToken != null) {
      try {
        await _dio.post(
          '/auth/logout',
          data: {
            'refresh_token': refreshToken,
          },
        );
      } catch (_) {}
    }

    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: 'access_token');
  }

  String _getErrorMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }

    if (e.response?.statusCode == 401) {
      return 'E-mail ou senha incorretos.';
    }

    if (e.response?.statusCode == 409) {
      return 'Este e-mail já está cadastrado.';
    }

    if (e.response?.statusCode == 429) {
      return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
    }

    return 'Erro ao conectar com o servidor.';
  }
}