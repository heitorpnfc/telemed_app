class ApiConfig {
  // O aplicativo conectará em produção (VPS) por padrão.
  // Para testar usando Ngrok localmente, execute o app no terminal da seguinte forma:
  // flutter run --dart-define=API_BASE_URL=https://seu-endereco-ngrok.ngrok-free.app
  
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://remindcare.com.br',
  );
}