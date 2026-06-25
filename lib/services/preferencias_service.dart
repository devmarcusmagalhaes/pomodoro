// lib/services/preferencias_service.dart

// Camada de acesso ao SharedPreferences para preferências leves e sem estrutura.

// MUDANÇA DA PARTE 3:
//   - A sessão ativa (auto-login) passou a ser responsabilidade do Firebase
//     Auth, que persiste o login automaticamente. Restou aqui apenas o último
//     tempo de timer escolhido pelo usuário (melhoria de UX).


import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasService {
  static const _keyTempoPadrao = 'tempo_padrao_min';

  /// Último tempo (em minutos) escolhido pelo usuário. Restaurado ao abrir o
  /// app, evitando que ele precise re-selecionar toda vez.
  Future<int?> lerTempoPadrao() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTempoPadrao);
  }

  Future<void> gravarTempoPadrao(int minutos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTempoPadrao, minutos);
  }
}
