// lib/views/tela_pomodoro.dart

// MUDANÇAS DA PARTE 2:
//   - Logout é async e exige confirmação do usuário (melhoria de UX).
//   - Novo botão de Perfil na AppBar (tooltip + navegação).
//   - `limparEstado()` no logout (substitui o antigo `reiniciar()`).
//   - Tooltips adicionados aos ícones (acessibilidade).


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/pomodoro_controller.dart';
import '../core/constants.dart';
import '../widgets/day_bar_row.dart';
import '../widgets/session_stats_card.dart';
import '../widgets/timer_display.dart';
import 'tela_login.dart';
import 'tela_mapa_estudos.dart';
import 'tela_perfil.dart';

class TelaPomodoro extends StatefulWidget {
  const TelaPomodoro({super.key});

  @override
  State<TelaPomodoro> createState() => _TelaPomodoroState();
}

class _TelaPomodoroState extends State<TelaPomodoro>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final PomodoroController _pomodoro;
  final _campoCtrl = TextEditingController();
  String? _erroCustom;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _pomodoro = context.read<PomodoroController>();
    _pomodoro.addListener(_onPomodoroChanged);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _campoCtrl.dispose();
    _pomodoro.removeListener(_onPomodoroChanged);
    super.dispose();
  }

  void _onPomodoroChanged() {
    if (_pomodoro.sessaoRecemConcluida) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarConclusao();
      });
    }
  }

  void _aplicarCustom() {
    final erro = _pomodoro.validarTempoCustom(_campoCtrl.text);
    setState(() => _erroCustom = erro);
    if (erro != null) return;
    _pomodoro.selecionarMinutos(int.parse(_campoCtrl.text.trim()));
    _campoCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  void _mostrarConclusao() {
    final nome =
        context.read<AuthController>().usuario?.nome.split(' ').first;
    final minutos = _pomodoro.minutosEscolhidos;
    final frase = _pomodoro.fraseMotivacional;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('🎉 Sessão concluída!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Você focou por $minutos min. Parabéns, $nome!'),
            // Parte 3: frase motivacional vinda da API.
            if (frase != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${frase.texto}"',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '— ${frase.autor}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pomodoro.confirmarConclusao();
            },
            child: const Text('Nova sessão'),
          ),
        ],
      ),
    );
  }

  /// Logout com confirmação. Limpa o estado em memória após o sair.
  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja encerrar a sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    await context.read<AuthController>().sair();
    if (!mounted) return;
    _pomodoro.limparEstado();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TelaLogin()),
    );
  }

  void _abrirPerfil() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaPerfil()),
    );
  }

  void _abrirMapa() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaMapaEstudos()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pomodoro Semanal',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              usuario?.email ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Mapa de estudos',
            onPressed: _abrirMapa,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: _abrirPerfil,
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.deepOrange,
          tabs: const [
            Tab(icon: Icon(Icons.timer_outlined), text: 'Timer'),
            Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Semana'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _TimerTab(
            campoCtrl: _campoCtrl,
            erroCustom: _erroCustom,
            aplicarCustom: _aplicarCustom,
            onErroChanged: (e) => setState(() => _erroCustom = e),
          ),
          const _SemanaTab(),
        ],
      ),
    );
  }
}

// ── _TimerTab — controles do timer e seleção de tempo ───────────────────────

class _TimerTab extends StatelessWidget {
  final TextEditingController campoCtrl;
  final String? erroCustom;
  final VoidCallback aplicarCustom;
  final ValueChanged<String?> onErroChanged;

  const _TimerTab({
    required this.campoCtrl,
    required this.erroCustom,
    required this.aplicarCustom,
    required this.onErroChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          TimerDisplay(
            tempo: pomodoro.tempoFormatado,
            progresso: pomodoro.progresso,
            estado: pomodoro.estado,
            minutosEscolhidos: pomodoro.minutosEscolhidos,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: opcoesPredefinidas
                .map(
                  (min) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text('$min min'),
                      selected: pomodoro.minutosEscolhidos == min &&
                          campoCtrl.text.isEmpty,
                      selectedColor: Colors.deepOrange.shade100,
                      onSelected: pomodoro.estado == EstadoTimer.rodando
                          ? null
                          : (_) => pomodoro.selecionarMinutos(min),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: campoCtrl,
                  keyboardType: TextInputType.number,
                  enabled: pomodoro.estado != EstadoTimer.rodando,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Tempo personalizado',
                    suffixText: 'min',
                    errorText: erroCustom,
                  ),
                  onChanged: (_) {
                    if (erroCustom != null) onErroChanged(null);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton(
                  onPressed: pomodoro.estado == EstadoTimer.rodando
                      ? null
                      : aplicarCustom,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    minimumSize: const Size(60, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: switch (pomodoro.estado) {
                  EstadoTimer.aguardando => pomodoro.iniciar,
                  EstadoTimer.rodando    => pomodoro.pausar,
                  EstadoTimer.pausado    => pomodoro.iniciar,
                },
                icon: Icon(pomodoro.estado == EstadoTimer.rodando
                    ? Icons.pause
                    : Icons.play_arrow),
                label: Text(switch (pomodoro.estado) {
                  EstadoTimer.aguardando => 'Iniciar',
                  EstadoTimer.rodando    => 'Pausar',
                  EstadoTimer.pausado    => 'Retomar',
                }),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (pomodoro.estado != EstadoTimer.aguardando) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: pomodoro.reiniciar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
          if (pomodoro.sessoes.isNotEmpty) ...[
            const SizedBox(height: 28),
            SessionStatsCard(
              sessoesSemana: pomodoro.sessoesNaSemana.length,
              totalFormatado: pomodoro.totalMinutosSemana == 0
                  ? '0min'
                  : formatarDuracao(pomodoro.totalMinutosSemana),
              totalSessoes: pomodoro.sessoes.length,
            ),
          ],
        ],
      ),
    );
  }
}

// ── _SemanaTab — visualização semanal por dia ───────────────────────────────

class _SemanaTab extends StatelessWidget {
  const _SemanaTab();

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroController>();
    final porDia = pomodoro.minutosPorDia;
    final maxMin =
        porDia.values.fold(0, (a, b) => a > b ? a : b).toDouble();
    final total = pomodoro.totalMinutosSemana;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepOrange.shade400,
                  Colors.deepOrange.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você estudou esta semana',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0 ? '0 min' : formatarDuracao(total),
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  '${pomodoro.sessoesNaSemana.length} sessão(ões) concluída(s)',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Distribuição por dia',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Nenhuma sessão ainda.\nInicie um Pomodoro para começar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ),
            )
          else
            ...porDia.entries.map(
              (e) => DayBarRow(
                dia: e.key,
                minutos: e.value,
                proporcao: maxMin > 0 ? e.value / maxMin : 0.0,
              ),
            ),
        ],
      ),
    );
  }
}
