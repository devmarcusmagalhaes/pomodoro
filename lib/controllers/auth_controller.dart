// lib/controllers/auth_controller.dart
// MUDANÇAS DA PARTE 2:
//Métodos agora são assíncronos (o banco e o SharedPreferences são async).
//Novo `carregarSessaoAtiva()` para auto-login na splash.
//Novo `excluirConta()` para a tela de perfil.

import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final _service = AuthService();
  Usuario? _usuario;

  Usuario? get usuario => _usuario;
  bool get autenticado => _usuario != null;

  //Delegação de validações (síncronas)
  String? validarNome(String? v)  => _service.validarNome(v);
  String? validarLogin(String? v) => _service.validarLogin(v);
  String? validarSenha(String? v) => _service.validarSenha(v);
  String? validarConfirmar(String? v, String senha) =>
      _service.validarConfirmar(v, senha);
  bool loginEmUso(String login) => _service.loginEmUso(login);

  //Autenticação assíncrona

  ///Tenta autenticar. Retorna o [Usuario] em caso de sucesso ou `null` se
  //as credenciais não conferem.
  Future<Usuario?> entrar(String login, String senha) async {
    _usuario = await _service.entrar(login, senha);
    if (_usuario != null) notifyListeners();
    return _usuario;
  }

  //Cria conta e autentica o usuário recém-criado.
  //Pode lançar [StateError] se o login já existir.
  Future<Usuario> cadastrar(String nome, String login, String senha) async {
    _usuario = await _service.cadastrar(nome, login, senha);
    notifyListeners();
    return _usuario!;
  }

  //Encerra a sessão ativa.
  Future<void> sair() async {
    await _service.sair();
    _usuario = null;
    notifyListeners();
  }

  //Restaura a sessão anterior (chamado na splash).
  //Retorna `true` se havia um usuário logado.
  Future<bool> carregarSessaoAtiva() async {
    _usuario = await _service.carregarSessaoAtiva();
    if (_usuario != null) notifyListeners();
    return _usuario != null;
  }

  //Exclui a conta do usuário atual e finaliza a sessão.
  //As sessões de estudo devem ser limpas pelo chamador
  //(ver `PomodoroController.limparEstado`).
  Future<void> excluirConta() async {
    if (_usuario == null) return;
    await _service.excluirConta(_usuario!.login);
    _usuario = null;
    notifyListeners();
  }
}
