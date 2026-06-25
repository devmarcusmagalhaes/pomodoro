// lib/views/tela_splash.dart

// Tela exibida ao abrir o app. Responsável por:
//   1. Verificar se houve falha na inicialização do banco (mostra erro).
//   2. Tentar auto-login (recupera sessão anterior).
//   3. Pré-carregar o histórico de sessões antes de navegar.
//   4. Redirecionar para TelaLogin ou TelaPomodoro conforme o estado.


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/pomodoro_controller.dart';
import '../services/db_service.dart';
import 'tela_login.dart';
import 'tela_pomodoro.dart';

class TelaSplash extends StatefulWidget {
  const TelaSplash({super.key});

  @override
  State<TelaSplash> createState() => _TelaSplashState();
}

class _TelaSplashState extends State<TelaSplash> {
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback garante que o context já está montado antes
    // de usarmos Provider.of / context.read.
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarSessao());
  }

  Future<void> _verificarSessao() async {
    // Se o Hive falhou, mantemos a splash com mensagem de erro.
    if (!DbService.inicializado) {
      if (mounted) setState(() {});
      return;
    }

    final auth = context.read<AuthController>();
    final logado = await auth.carregarSessaoAtiva();
    if (!mounted) return;

    if (logado) {
      // Pré-carrega o histórico antes da navegação, evitando "flash" de UI.
      await context
          .read<PomodoroController>()
          .carregarSessoes(auth.usuario!.uid);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TelaPomodoro()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TelaLogin()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final houveErro = !DbService.inicializado;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍅', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              if (houveErro) ...[
                Icon(Icons.error_outline,
                    color: Colors.red.shade400, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Falha ao inicializar o banco de dados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${DbService.erroInicializacao}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ] else ...[
                const CircularProgressIndicator(color: Colors.deepOrange),
                const SizedBox(height: 16),
                Text(
                  'Carregando…',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
