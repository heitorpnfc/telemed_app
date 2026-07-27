import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String url;
  final String releaseNotes;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.url,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'],
      buildNumber: json['build_number'],
      url: json['url'],
      releaseNotes: json['release_notes'],
    );
  }
}

class UpdateService {
  final Dio _dio = Dio();
  final String _versionUrl = "https://remindcare.com.br/version.json";

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get(_versionUrl, options: Options(
        responseType: ResponseType.json,
        headers: {
          // Bypass caches to always get the latest version JSON
          'Cache-Control': 'no-cache',
        }
      ));
      
      if (response.statusCode == 200) {
        final updateInfo = UpdateInfo.fromJson(response.data);
        final packageInfo = await PackageInfo.fromPlatform();
        
        final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
        
        // Se a build number do servidor for maior que a do app atual
        if (updateInfo.buildNumber > currentBuildNumber) {
          return updateInfo;
        }
      }
      return null;
    } catch (e) {
      print("Erro ao verificar atualização: $e");
      return null;
    }
  }

  Future<void> downloadAndInstallUpdate(String url, Function(double) onProgress) async {
    try {
      // Pega o diretório temporário do sistema
      final tempDir = await getTemporaryDirectory();
      final savePath = "${tempDir.path}/remindcare-update.apk";

      // Faz o download do APK
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      // Inicia a instalação chamando o intent do Android
      final result = await OpenFilex.open(savePath);
      print("Resultado da abertura do APK: ${result.message}");
      
    } catch (e) {
      print("Erro ao baixar/instalar atualização: $e");
    }
  }
}
