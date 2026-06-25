// lib/controllers/mapa_controller.dart  ← NOVO na Parte 3

// Agrega as sessões que possuem geolocalização em "locais de estudo".
// Sessões no mesmo lugar (mesmo nome, ou coordenadas muito próximas) são
// somadas, formando pontos no mapa com o tempo total estudado ali.

import 'package:flutter/foundation.dart';

import '../models/local_estudo.dart';
import '../models/sessao_estudo.dart';

class MapaController extends ChangeNotifier {
  List<LocalEstudo> _locais = [];
  List<LocalEstudo> get locais => _locais;

  bool get temLocais => _locais.isNotEmpty;

  /// Recalcula os locais de estudo a partir da lista de sessões.
  void carregar(List<SessaoEstudo> sessoes) {
    final comLocalizacao = sessoes.where((s) => s.temLocalizacao);

    // Agrupa por uma chave estável: nome do local, ou coordenada arredondada
    // (~3 casas ≈ 110 m) quando o nome não foi obtido.
    final grupos = <String, List<SessaoEstudo>>{};
    for (final s in comLocalizacao) {
      final chave = s.local ??
          '${s.latitude!.toStringAsFixed(3)},${s.longitude!.toStringAsFixed(3)}';
      grupos.putIfAbsent(chave, () => []).add(s);
    }

    _locais = grupos.entries.map((entrada) {
      final lista = entrada.value;
      final totalMin = lista.fold(0, (acc, s) => acc + s.minutos);
      return LocalEstudo(
        nome        : lista.first.local ?? 'Local sem nome',
        latitude    : lista.first.latitude!,
        longitude   : lista.first.longitude!,
        totalMinutos: totalMin,
        totalSessoes: lista.length,
      );
    }).toList()
      // Ordena do mais estudado para o menos estudado.
      ..sort((a, b) => b.totalMinutos.compareTo(a.totalMinutos));

    notifyListeners();
  }
}
