import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/pomodoro_controller.dart';
import '../core/constants.dart';
import '../services/sessao_service.dart';
import 'tela_login.dart';

class TelaPerfil extends StatelessWidget {
  const TelaPerfil({super.key});

  Future<void> _excluirConta(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Isso apagará seu usuário e todo o histórico de sessões. '
          'Esta ação é irreversível. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;

    //Captura o login antes de zerar o controller.
    final login = context.read<AuthController>().usuario?.login;

    if (login != null) {
      await SessaoService().limpar(login);
      if (!context.mounted) return;
    }
    await context.read<AuthController>().excluirConta();
    if (!context.mounted) return;
    context.read<PomodoroController>().limparEstado();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const TelaLogin()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario;
    final pomodoro = context.watch<PomodoroController>();

    if (usuario == null) {
      //Estado defensivo — não deveria ocorrer (rota protegida).
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final iniciais = usuario.nome
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.deepOrange.shade100,
              child: Text(
                iniciais.isEmpty ? '🍅' : iniciais,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            usuario.nome,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(
            '@${usuario.login}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          _LinhaInfo(
            icone: Icons.calendar_today_outlined,
            titulo: 'Sessões no total',
            valor: '${pomodoro.sessoes.length}',
          ),
          _LinhaInfo(
            icone: Icons.timer_outlined,
            titulo: 'Tempo total estudado',
            valor: pomodoro.totalMinutosGeral == 0
                ? '0min'
                : formatarDuracao(pomodoro.totalMinutosGeral),
          ),
          _LinhaInfo(
            icone: Icons.local_fire_department_outlined,
            titulo: 'Esta semana',
            valor: pomodoro.totalMinutosSemana == 0
                ? '0min'
                : formatarDuracao(pomodoro.totalMinutosSemana),
          ),
          const SizedBox(height: 32),
          const Text(
            'Últimas sessões',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (pomodoro.sessoes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nenhuma sessão registrada ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          else
            ...pomodoro.sessoes.reversed.take(5).map(
                  (s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline,
                        color: Colors.deepOrange),
                    title: Text('${s.minutos} minutos'),
                    subtitle: Text(_formatarData(s.data)),
                  ),
                ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () => _excluirConta(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Excluir conta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatarData(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final hora = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dia/$mes às $hora:$min';
  }
}

class _LinhaInfo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;

  const _LinhaInfo({
    required this.icone,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icone, color: Colors.deepOrange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(titulo, style: const TextStyle(fontSize: 15)),
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
