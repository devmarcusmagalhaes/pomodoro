
import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasService {
  static const _keyLoginAtivo  = 'login_ativo';
  static const _keyTempoPadrao = 'tempo_padrao_min';

  //Sessão ativa (auto-login)

  Future<String?> lerLoginAtivo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLoginAtivo);
  }

  Future<void> gravarLoginAtivo(String login) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLoginAtivo, login);
  }

  Future<void> limparLoginAtivo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoginAtivo);
  }

  //Tempo padrão do timer (melhoria de UX)

  //Último tempo (em minutos) escolhido pelo usuário. Restaurado ao abrir o
  //app, evitando que ele precise re-selecionar toda vez.
  Future<int?> lerTempoPadrao() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTempoPadrao);
  }

  Future<void> gravarTempoPadrao(int minutos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTempoPadrao, minutos);
  }
}
