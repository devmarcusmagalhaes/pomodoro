// lib/controllers/pomodoro_controller.dart

// MUDANÇAS DA PARTE 3:
//  Captura de GPS ao iniciar a sessão (best-effort, não bloqueia o timer).
//  Geocodificação reversa do local capturado (API Nominatim).
//  Frase motivacional buscada na API ao concluir a sessão.
//  A sessão salva passa a carregar latitude/longitude/local.

// MUDANÇAS DA PARTE 2 (mantidas):
//  Sessões persistidas via SessaoService; tempo padrão em SharedPreferences.


import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../core/result.dart';
import '../models/sessao_estudo.dart';
import '../repositories/sessao_repository.dart';
import '../services/frase_service.dart';
import '../services/geocodificacao_service.dart';
import '../services/localizacao_service.dart';
import '../services/preferencias_service.dart';

enum EstadoTimer { aguardando, rodando, pausado }

class PomodoroController extends ChangeNotifier {
  final _sessaoRepository = SessaoRepository();
  final _prefs = PreferenciasService();

  // ── Parte 3: serviços externos (GPS + APIs) 
  final _localizacaoService = LocalizacaoService();
  final _geocodificacaoService = GeocodificacaoService();
  final _fraseService = FraseService();

  int minutosEscolhidos = tempoPadraoMin;
  int segundosRestantes = tempoPadraoMin * 60;
  EstadoTimer estado = EstadoTimer.aguardando;
  Timer? _timer;

  List<SessaoEstudo> sessoes = [];
  bool _sessaoRecemConcluida = false;
  String? _uidAtual; // uid do usuário autenticado (escopo das sessões)

  // Parte 3: estado de localização e frase
  Coordenada? _coordCapturada;
  String? _localCapturado;
  Frase? _fraseMotivacional;

  // Getters 

  bool get sessaoRecemConcluida => _sessaoRecemConcluida;
  String? get uidAtual => _uidAtual;
  Frase? get fraseMotivacional => _fraseMotivacional;

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

  // Persistência
  Future<void> carregarSessoes(String uid) async {
    _uidAtual = uid;
    sessoes = await _sessaoRepository.carregar(uid);

    final tempo = await _prefs.lerTempoPadrao();
    if (tempo != null && tempo >= tempoMinimoMin && tempo <= tempoMaximoMin) {
      minutosEscolhidos = tempo;
      segundosRestantes = tempo * 60;
    }

    notifyListeners();
  }

  void limparEstado() {
    _timer?.cancel();
    minutosEscolhidos = tempoPadraoMin;
    segundosRestantes = tempoPadraoMin * 60;
    estado = EstadoTimer.aguardando;
    _sessaoRecemConcluida = false;
    sessoes = [];
    _uidAtual = null;
    _coordCapturada = null;
    _localCapturado = null;
    _fraseMotivacional = null;
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

  // Controle do timer 

  void iniciar() {
    estado = EstadoTimer.rodando;
    notifyListeners();

    // Parte 3: captura o local ao iniciar (assíncrono, não bloqueia o timer).
    _capturarLocalizacao();

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

    HapticFeedback.selectionClick();
    _prefs.gravarTempoPadrao(min);

    notifyListeners();
  }

  void confirmarConclusao() {
    _sessaoRecemConcluida = false;
    reiniciar();
  }

  //Parte 3: captura de localização (GPS + geocodificação)

  /// Obtém a coordenada atual e o nome do local. Tudo best-effort: se o GPS
  /// ou a API falharem, a sessão é salva sem localização.
  Future<void> _capturarLocalizacao() async {
    _coordCapturada = null;
    _localCapturado = null;

    final resultadoGps = await _localizacaoService.obterLocalizacaoAtual();
    if (resultadoGps is! Ok<Coordenada>) return;

    final coord = resultadoGps.value;
    _coordCapturada = coord;

    final resultadoNome =
        await _geocodificacaoService.nomeDoLocal(coord.latitude, coord.longitude);
    if (resultadoNome is Ok<String>) {
      _localCapturado = resultadoNome.value;
    }
  }

  // Tick interno (com persistência + APIs)

  Future<void> _tick(Timer t) async {
    if (segundosRestantes > 0) {
      segundosRestantes--;
      notifyListeners();
      return;
    }

    t.cancel();
    HapticFeedback.heavyImpact();

    final nova = SessaoEstudo(
      data     : DateTime.now(),
      minutos  : minutosEscolhidos,
      latitude : _coordCapturada?.latitude,
      longitude: _coordCapturada?.longitude,
      local    : _localCapturado,
    );
    sessoes.add(nova);

    if (_uidAtual != null) {
      try {
        // Repositório offline-first: grava no Hive e sincroniza no Firestore.
        await _sessaoRepository.adicionar(_uidAtual!, nova);
      } catch (_) {
        // Persistência falhou, mas a sessão permanece em memória.
      }
    }

    // Parte 3: busca a frase motivacional para o diálogo de conclusão.
    _fraseMotivacional = await _fraseService.fraseAleatoria();

    // Limpa a captura para a próxima sessão.
    _coordCapturada = null;
    _localCapturado = null;

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
