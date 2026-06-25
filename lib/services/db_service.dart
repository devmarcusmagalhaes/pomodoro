// lib/services/db_service.dart
//
// MUDANÇA DA PARTE 3:
//   A autenticação migrou para o Firebase Auth, então a box "usuarios" do
//   Hive não é mais necessária. O Hive agora serve apenas como CACHE LOCAL
//   OFFLINE das sessões (box "sessoes"), espelhando o Firestore.


import 'package:hive_flutter/hive_flutter.dart';

class DbService {
  static const _boxSessoes = 'sessoes';

  static bool _inicializado = false;
  static Object? _erroInicializacao;

  static bool get inicializado => _inicializado;
  static Object? get erroInicializacao => _erroInicializacao;

  /// Deve ser chamado UMA vez em [main], antes de `runApp`.
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(_boxSessoes);
      _inicializado = true;
    } catch (e) {
      _erroInicializacao = e;
      _inicializado = false;
    }
  }

  /// Box de cache local das sessões (chave = uid → List<Map>).
  static Box get sessoes => Hive.box(_boxSessoes);
}
