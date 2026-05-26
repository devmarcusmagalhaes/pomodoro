import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../models/sessao_estudo.dart';
import '../services/preferencias_service.dart';
import '../services/sessao_service.dart';

enum EstadoTimer { aguardando, rodando, pausado }

class PomodoroController extends ChangeNotifier {
  final _sessaoService = SessaoService();
  final _prefs = PreferenciasService();

  int minutosEscolhidos = tempoPadraoMin;
  int segundosRestantes = tempoPadraoMin * 60;
  EstadoTimer estado = EstadoTimer.aguardando;
  Timer? _timer;

  List<SessaoEstudo> sessoes = [];
  bool _sessaoRecemConcluida = false;
  String? _loginAtual;

  //Getters 

  bool get sessaoRecemConcluida => _sessaoRecemConcluida;
  String? get loginAtual => _loginAtual;

  double get progresso =>
      1 - (segundosRestantes / (minutosEscolhidos * 60));

  String get tempoFormatado {
    final m = (segundosRestantes ~/ 60).toString().padLeft(2, '0');
    final s = (segundosRestantes % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  List<SessaoEstudo> get sessoesNaSemana =>
      sessoes.where((s) => s.estaSemanAtual).toList();

  int get totalMinutosSemana =>
      sessoesNaSemana.fold(0, (acc, s) => acc + s.minutos);

  int get totalMinutosGeral =>
      sessoes.fold(0, (acc, s) => acc + s.minutos);

  Map<String, int> get minutosPorDia {
    final dias = {
      'Seg': 0, 'Ter': 0, 'Qua': 0, 'Qui': 0,
      'Sex': 0, 'Sáb': 0, 'Dom': 0,
    };
    const nomes = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    for (final s in sessoesNaSemana) {
      final dia = nomes[s.data.weekday];
      dias[dia] = (dias[dia] ?? 0) + s.minutos;
    }
    return dias;
  }

  //Persistência

  //Carrega o histórico do usuário e o tempo padrão preferido.
  //Chamado após o login (ou na splash em caso de auto-login).
  Future<void> carregarSessoes(String login) async {
    _loginAtual = login;
    sessoes = await _sessaoService.carregar(login);

    // Restaura o último tempo escolhido pelo usuário, se válido.
    final tempo = await _prefs.lerTempoPadrao();
    if (tempo != null && tempo >= tempoMinimoMin && tempo <= tempoMaximoMin) {
      minutosEscolhidos = tempo;
      segundosRestantes = tempo * 60;
    }

    notifyListeners();
  }

  //Limpa estado do timer e histórico em memória.
  //Chamado no logout ou na exclusão da conta.
  void limparEstado() {
    _timer?.cancel();
    minutosEscolhidos = tempoPadraoMin;
    segundosRestantes = tempoPadraoMin * 60;
    estado = EstadoTimer.aguardando;
    _sessaoRecemConcluida = false;
    sessoes = [];
    _loginAtual = null;
    notifyListeners();
  }

  //Validação

  String? validarTempoCustom(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe o tempo em minutos.';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Digite apenas números inteiros.';
    if (n < tempoMinimoMin) return 'Mínimo $tempoMinimoMin minuto.';
    if (n > tempoMaximoMin) return 'Máximo $tempoMaximoMin minutos.';
    return null;
  }

  //Controle do timer

  void iniciar() {
    estado = EstadoTimer.rodando;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void pausar() {
    _timer?.cancel();
    estado = EstadoTimer.pausado;
    notifyListeners();
  }

  void reiniciar() {
    _timer?.cancel();
    segundosRestantes = minutosEscolhidos * 60;
    estado = EstadoTimer.aguardando;
    notifyListeners();
  }

  void selecionarMinutos(int min) {
    _timer?.cancel();
    minutosEscolhidos = min;
    segundosRestantes = min * 60;
    estado = EstadoTimer.aguardando;

    //Melhoria de UX: feedback tátil + persistência da preferência.
    HapticFeedback.selectionClick();
    _prefs.gravarTempoPadrao(min);

    notifyListeners();
  }

  void confirmarConclusao() {
    _sessaoRecemConcluida = false;
    reiniciar();
  }

  //Tick interno (com persistência)

  Future<void> _tick(Timer t) async {
    if (segundosRestantes > 0) {
      segundosRestantes--;
      notifyListeners();
      return;
    }

    t.cancel();
    HapticFeedback.heavyImpact();

    final nova = SessaoEstudo(
      data   : DateTime.now(),
      minutos: minutosEscolhidos,
    );
    sessoes.add(nova);

    //Aguardamos a gravação para evitar perda em caso de fechamento abrupto
    //logo após o término do timer. O erro é silenciado: a sessão segue em
    //memória mesmo se o banco falhar (registro em log seria o ideal em prod).
    if (_loginAtual != null) {
      try {
        await _sessaoService.adicionar(_loginAtual!, nova);
      } catch (_) {
      // Persistência falhou, mas a sessão permanece em memória.
      }
    }

    estado = EstadoTimer.aguardando;
    _sessaoRecemConcluida = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
