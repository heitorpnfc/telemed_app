import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'user_service.dart';

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

      // Sincroniza FCM Token com o backend
      await UserService().syncFcmToken();

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
    final accessToken =
        await _storage.read(key: 'access_token');

    final refreshToken =
        await _storage.read(key: 'refresh_token');

    // Se tiver um access_token válido e não expirado, está logado.
    if (accessToken != null && accessToken.isNotEmpty) {
      if (!_isTokenExpired(accessToken)) {
        return true;
      }
    }

    // Se o access_token expirou mas ainda tem refresh_token,
    // considera logado (o ApiClient fará o refresh automaticamente).
    if (refreshToken != null && refreshToken.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// Decodifica o payload do JWT e verifica se o campo `exp`
  /// já passou em relação ao horário atual do dispositivo.
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // O payload é a segunda parte do JWT, codificada em Base64Url.
      String payload = parts[1];

      // Base64Url exige padding para múltiplo de 4.
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> data = jsonDecode(decoded);

      final exp = data['exp'];
      if (exp == null) return true;

      final expDate = DateTime.fromMillisecondsSinceEpoch(
        exp * 1000,
      );

      // Considera expirado se faltar menos de 30 segundos.
      return DateTime.now().isAfter(
        expDate.subtract(const Duration(seconds: 30)),
      );
    } catch (_) {
      // Se não conseguir decodificar, assume expirado.
      return true;
    }
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