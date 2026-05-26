// Tela principal do aplicativo (Contém as abas de Cronômetro e Estatísticas da Semana)
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
import 'tela_perfil.dart';

class TelaPomodoro extends StatefulWidget {
  const TelaPomodoro({super.key});

  @override
  State<TelaPomodoro> createState() => _TelaPomodoroState();
}

// O SingleTickerProviderStateMixin é obrigatório para usar animações de abas (TabController)
class _TelaPomodoroState extends State<TelaPomodoro> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final PomodoroController _pomodoro;
  final _campoCtrl = TextEditingController();
  String? _erroCustom;

  @override
  void initState() {
    super.initState();
    // Configura o controlador das 2 abas (Timer e Semana)
    _tabs = TabController(length: 2, vsync: this);
    _pomodoro = context.read<PomodoroController>();
    
    // Fica "escutando" o cronômetro para saber quando ele zera
    _pomodoro.addListener(_onPomodoroChanged);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _campoCtrl.dispose();
    _pomodoro.removeListener(_onPomodoroChanged);
    super.dispose();
  }

  // Função chamada toda vez que o estado do Pomodoro muda
  void _onPomodoroChanged() {
    // Se a sessão acabou de chegar a zero...
    if (_pomodoro.sessaoRecemConcluida) {
      // Espera a tela terminar de desenhar para mostrar o pop-up, evitando erros de renderização
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarConclusao();
      });
    }
  }

  // Aplica o tempo que o usuário digitou manualmente
  void _aplicarCustom() {
    final erro = _pomodoro.validarTempoCustom(_campoCtrl.text);
    setState(() => _erroCustom = erro);
    
    if (erro != null) return; // Se deu erro (ex: tempo negativo), para por aqui
    
    _pomodoro.selecionarMinutos(int.parse(_campoCtrl.text.trim()));
    _campoCtrl.clear();
    FocusScope.of(context).unfocus(); // Esconde o teclado
  }

  // Pop-up de parabéns quando o tempo acaba
  void _mostrarConclusao() {
    final nome = context.read<AuthController>().usuario?.nome.split(' ').first;
    final minutos = _pomodoro.minutosEscolhidos;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('🎉 Sessão concluída!'),
        content: Text('Você focou por $minutos min. Parabéns, $nome!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pomodoro.confirmarConclusao(); // Reseta o estado para iniciar um novo
            },
            child: const Text('Nova sessão'),
          ),
        ],
      ),
    );
  }

  // Processo de Logout
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
    
    _pomodoro.limparEstado(); // Limpa os dados do usuário antigo da memória
    
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
              '@${usuario?.login ?? ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
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

// ABA 1: TAB DO CRONÔMETRO 
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

    // Lógica do botão principal extraída para facilitar a leitura
    String textoBotaoAcao = 'Iniciar';
    IconData iconeBotaoAcao = Icons.play_arrow;
    VoidCallback acaoDoBotao = pomodoro.iniciar;

    if (pomodoro.estado == EstadoTimer.rodando) {
      textoBotaoAcao = 'Pausar';
      iconeBotaoAcao = Icons.pause;
      acaoDoBotao = pomodoro.pausar;
    } else if (pomodoro.estado == EstadoTimer.pausado) {
      textoBotaoAcao = 'Retomar';
      iconeBotaoAcao = Icons.play_arrow;
      acaoDoBotao = pomodoro.iniciar;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Chama aquele widget que desenha o círculo do tempo
          TimerDisplay(
            tempo: pomodoro.tempoFormatado,
            progresso: pomodoro.progresso,
            estado: pomodoro.estado,
            minutosEscolhidos: pomodoro.minutosEscolhidos,
          ),
          const SizedBox(height: 32),
          
          // BOTÕES DE TEMPO RÁPIDO (Ex: 15min, 25min)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: opcoesPredefinidas.map((min) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text('$min min'),
                  selected: pomodoro.minutosEscolhidos == min && campoCtrl.text.isEmpty,
                  selectedColor: Colors.deepOrange.shade100,
                  onSelected: pomodoro.estado == EstadoTimer.rodando
                      ? null // Desabilita o clique se estiver contando o tempo
                      : (_) => pomodoro.selecionarMinutos(min),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          
          // CAMPO DE TEMPO PERSONALIZADO
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: campoCtrl,
                  keyboardType: TextInputType.number,
                  enabled: pomodoro.estado != EstadoTimer.rodando,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Bloqueia letras
                  decoration: InputDecoration(
                    labelText: 'Tempo personalizado',
                    suffixText: 'min',
                    errorText: erroCustom,
                  ),
                  onChanged: (_) {
                    if (erroCustom != null) onErroChanged(null); // Limpa o erro ao digitar
                  },
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton(
                  onPressed: pomodoro.estado == EstadoTimer.rodando ? null : aplicarCustom,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    minimumSize: const Size(60, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          //BOTÕES DE PLAY/PAUSE E REINICIAR
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: acaoDoBotao,
                icon: Icon(iconeBotaoAcao),
                label: Text(textoBotaoAcao),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              // O botão de reiniciar só aparece se o tempo não estiver na estaca zero
              if (pomodoro.estado != EstadoTimer.aguardando) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: pomodoro.reiniciar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(color: Colors.deepOrange),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
          
          // CARTÃO DE ESTATÍSTICAS RÁPIDAS
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

// ABA 2: TAB DE ESTATÍSTICAS DA SEMANA
class _SemanaTab extends StatelessWidget {
  const _SemanaTab();

  @override
  Widget build(BuildContext context) {
    final pomodoro = context.watch<PomodoroController>();
    final porDia = pomodoro.minutosPorDia; // Traz um mapa: {'Seg': 25, 'Ter': 0...}
    
    // Acha qual foi o dia com mais minutos estudados para usar como 100% da barra
    final maxMin = porDia.values.fold(0, (a, b) => a > b ? a : b).toDouble();
    final total = pomodoro.totalMinutosSemana;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABEÇALHO COM GRADIENTE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você estudou esta semana',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0 ? '0 min' : formatarDuracao(total),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  '${pomodoro.sessoesNaSemana.length} sessão(ões) concluída(s)',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          
          const Text('Distribuição por dia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          
          // LISTA DE BARRINHAS DIÁRIAS
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
            // Para cada dia da semana, desenha aquela linha de gráfico que ajustamos antes
            ...porDia.entries.map(
              (diaMap) => DayBarRow(
                dia: diaMap.key,
                minutos: diaMap.value,
                // Calcula a porcentagem da barra em relação ao melhor dia da semana
                proporcao: maxMin > 0 ? diaMap.value / maxMin : 0.0,
              ),
            ),
        ],
      ),
    );
  }
}