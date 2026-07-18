# RemindCare - Mobile App 💙📱

Este repositório contém o código-fonte do aplicativo móvel da **RemindCare**, uma solução completa em saúde desenvolvida em **Flutter** para auxiliar familiares e cuidadores a monitorar a adesão médica de pacientes, de forma remota e em tempo real.

O aplicativo funciona em conjunto com a **Smart Pillbox (Caixa Inteligente)** da RemindCare e se comunica com nosso backend robusto em Rust/Node.js.

## 🚀 Principais Funcionalidades

*   **💊 Gestão de Medicamentos:** Cadastro, edição e exclusão da grade de remédios diários do paciente.
*   **🔗 Pareamento IoT:** Conexão simples e rápida com a Caixa Inteligente através de um código de pareamento.
*   **🟢 Monitoramento em Tempo Real:** Indicador visual (Online/Offline) sinalizando se a caixa está conectada ao Wi-Fi e comunicando-se com os servidores (via *heartbeat*).
*   **📊 Dashboard Clínico:** Acompanhamento visual da adesão ao tratamento (Tomado no Horário, Antecipado, Atrasado e Esquecido).
*   **🚨 Push Notifications (FCM):** Alertas de alta prioridade enviados instantaneamente para o celular do cuidador caso o paciente não abra a caixa no horário programado.
*   **📄 Relatórios PDF:** Geração de relatórios semanais de adesão para compartilhamento com médicos.

## 🛠️ Tecnologias Utilizadas

*   **Framework:** Flutter / Dart
*   **Comunicação de Rede:** HTTP (Comunicação com API RESTful em Rust)
*   **Notificações:** Firebase Cloud Messaging (FCM)
*   **Arquitetura e Estado:** Padrão Provider / Services Pattern
*   **Autenticação:** JWT (JSON Web Tokens)

## 📦 Estrutura do Projeto

O projeto segue uma arquitetura baseada em serviços para separação clara de responsabilidades:

*   `lib/models/`: Estruturas de dados e serialização JSON.
*   `lib/services/`: Lógica de negócios e comunicação com a API (ex: `auth_service.dart`, `device_service.dart`).
*   `lib/pages/`: Interfaces de usuário (Telas) como `HomePage`, `Dashboard`, `MedicineList`, etc.
*   `lib/widgets/`: Componentes visuais reutilizáveis.

## ⚙️ Pré-requisitos e Execução Local

1.  Certifique-se de ter o [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado na sua máquina (Versão atual: canal *Stable*).
2.  Clone o repositório e baixe as dependências:
    ```bash
    flutter pub get
    ```
3.  Execute o aplicativo em um emulador ou dispositivo físico (Android/iOS):
    ```bash
    flutter run
    ```
    *(Para simular o ambiente de produção em Release: `flutter run --release`)*

> [!WARNING]
> **Aviso de Segurança (Firebase):** O arquivo `google-services.json` contendo as chaves do Firebase foi removido do repositório por questões de segurança. Para rodar push notifications no seu ambiente de desenvolvimento, você precisará gerar um novo arquivo no console do Firebase e adicioná-lo à pasta `android/app/`.

## 🏗️ Como gerar o APK (Build de Produção)

O aplicativo foi configurado para otimizar ao máximo o peso da compilação e evitar bibliotecas desnecessárias. Para gerar a versão final para ser distribuída (ex: via Landing Page):

```bash
flutter build apk
```
O arquivo será gerado em: `build/app/outputs/flutter-apk/app-release.apk`

*Dica de Deploy:* Você pode enviar o arquivo gerado diretamente para a VPS através do SCP:
```bash
scp build/app/outputs/flutter-apk/app-release.apk root@<SEU_IP>:/root/remind_care_core/landing_page/remindcare-release.apk
```

---
*Desenvolvido com 💙 para garantir a tranquilidade de quem cuida e a independência de quem usa.*
