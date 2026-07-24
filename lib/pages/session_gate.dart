import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_page.dart';
import 'login_page.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();

    _sessionFuture = AuthService().isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState !=
            ConnectionState.done) {
          return const _StartupPage();
        }

        final isLoggedIn = snapshot.data ?? false;

        if (isLoggedIn) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}

class _StartupPage extends StatelessWidget {
  const _StartupPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F7FB),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_liquid_rounded,
              size: 72,
              color: Color(0xFF0A6CFF),
            ),
            SizedBox(height: 20),
            Text(
              'RemindCare',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}