// Tela de carregamento inicial (Splash Screen)
// Funciona como um "guarda de trânsito", decidindo para qual tela o usuário vai.
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
    // Espera a tela ser desenhada a primeira vez para depois rodar a verificação
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarSessao();
    });
  }

  // Função central que decide o destino do usuário
  Future<void> _verificarSessao() async {
    // 1. Tratamento de Erro Crítico: Verifica se o banco Hive abriu no main.dart
    if (!DbService.inicializado) {
      if (mounted) setState(() {}); // Atualiza a tela para mostrar a mensagem de erro
      return;
    }

    final auth = context.read<AuthController>();
    
    // 2. Tenta recuperar o último usuário logado (Auto-login)
    final usuarioJaEstavaLogado = await auth.carregarSessaoAtiva();
    if (!mounted) return;

    if (usuarioJaEstavaLogado) {
      // Puxa o histórico do banco antes de mudar de tela para a UI não dar "piscadas"
      await context.read<PomodoroController>().carregarSessoes(auth.usuario!.login);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TelaPomodoro()),
      );
    } else {
      // Se não tem ninguém logado, manda pra tela de Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TelaLogin()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool bancoDeuErro = !DbService.inicializado;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Faz a coluna ocupar só o centro da tela
            children: [
              const Text('🍅', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              
              // Se o banco deu erro, mostra o ícone vermelho e o motivo
              if (bancoDeuErro) ...[
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
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
              ] 
              // Se tá tudo bem, mostra a bolinha carregando
              else ...[
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