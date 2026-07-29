# 🍎 Guia Técnico: Compilação e Geração do iOS IPA via GitHub Actions

Este documento descreve toda a arquitetura, correções técnicas e o passo a passo utilizado para compilar o aplicativo **Telemed App (iOS)** na nuvem usando **GitHub Actions**, eliminando a necessidade de um computador Mac físico local com Xcode atualizado.

---

## 🎯 Contexto e Desafio

- **Problema:** Máquinas Mac antigas não possuem suporte às versões mais recentes do Xcode e dos SDKs nativos do iOS (ex: Firebase iOS SDK 12+ exige iOS 15.0+ e Swift 6).
- **Objetivo:** Gerar o arquivo compilado não-assinado `Runner-unsigned.ipa` para testes em iPhones de forma 100% automatizada e sem custo inicial com conta paga de desenvolvedor Apple ($99/ano).

---

## 🛠️ Arquitetura e Alterações Aplicadas

### 1. Configuração do Pipeline CI/CD (`.github/workflows/build_ios.yml`)

Criamos a esteira de integração contínua no GitHub Actions:

- **Runner:** `macos-15` (macOS com Xcode 16.0+ e suporte ao compilador Swift 6).
- **Desativação do SPM Experimental:** O Flutter 3.24+ ativa o Swift Package Manager por padrão. Desativamos essa flag via `flutter config --no-enable-swift-package-manager` para usar o **CocoaPods**, evitando conflitos de versão nos pods do Firebase.
- **Compilação Sem Código de Assinatura:** Execução do `flutter build ios --release --no-codesign`.
- **Empacotamento do IPA:** O binário gerado em `build/ios/iphoneos/Runner.app` é compactado na estrutura nativa de pacotes iOS (`Payload/Runner.app`) criando o `Runner-unsigned.ipa`.
- **Upload do Artefato:** Utilizado `actions/upload-artifact@v4` para disponibilizar o download do `.ipa` na aba *Actions*.

```yaml
name: Build iOS App

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build-ios:
    runs-on: macos-15

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Setup Java Development Kit (JDK 17)
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter SDK
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Disable Experimental Swift Package Manager
        run: flutter config --no-enable-swift-package-manager

      - name: Get Dependencies
        run: flutter pub get

      - name: Build iOS App (Unsigned Release)
        run: |
          flutter build ios --release --no-codesign || true
          if [ ! -d "build/ios/iphoneos/Runner.app" ]; then
            echo "Building via xcodebuild..."
            xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -sdk iphoneos CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" BUILD_DIR=build/ios build
          fi

      - name: Package Payload to IPA
        run: |
          mkdir -p Payload
          cp -r build/ios/iphoneos/Runner.app Payload/
          zip -r Runner-unsigned.ipa Payload

      - name: Upload iOS Build Artifact
        uses: actions/upload-artifact@v4
        with:
          name: telemed-app-ios-unsigned
          path: Runner-unsigned.ipa
          retention-days: 14
```

---

### 2. Elevação do Alvo de Implantação (iOS Deployment Target: 15.0)

O SDK nativo do Firebase exige versão mínima **iOS 15.0**.

1. **`ios/Podfile`:** Criado com a diretiva `platform :ios, '15.0'` e regra `post_install` que injeta `IPHONEOS_DEPLOYMENT_TARGET = '15.0'` em todas as dependências nativas.
2. **`ios/Runner.xcodeproj/project.pbxproj`:** Atualizada a variável `IPHONEOS_DEPLOYMENT_TARGET` de `13.0` para `15.0`.

---

### 3. Harmonização de Dependências (`pubspec.yaml`)

Para evitar conflitos sintáticos e de tipos de compilador durante a resolução multiplataforma (Dart/Objective-C/C++):

- `device_info_plus: ^10.1.0` (evita seletores experimentais do visionOS).
- `package_info_plus: ^9.0.0` (compatível com a resolução nativa do Win32/macOS).
- `syncfusion_flutter_pdfviewer: ^27.2.4` (alinhado com as dependências do ecossistema).

---

## 📲 Como Instalar e Testar no iPhone (Sideloading)

Como o `.ipa` gerado é **não-assinado (`unsigned`)**, ele pode ser instalado em qualquer iPhone gratuitamente usando um Apple ID comum:

1. Baixe o programa **Sideloadly** ([sideloadly.io](https://sideloadly.io/)) ou **AltStore** ([altstore.io](https://altstore.io/)).
2. Conecte o iPhone ao computador via cabo USB.
3. Arraste o arquivo `Runner-unsigned.ipa` para dentro do programa.
4. Insira seu Apple ID gratuito. O Sideloadly irá gerar o certificado temporário e instalar o aplicativo no iPhone.
5. No iPhone, vá em **Ajustes > Geral > Gestão de Dispositivos** e clique em **Confiar no Desenvolvedor**.
