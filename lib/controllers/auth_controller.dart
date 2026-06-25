// lib/controllers/auth_controller.dart

// MUDANÇAS DA PARTE 3:
//  Autenticação delegada ao AuthRepository (Firebase Auth + Firestore).
//  entrar/cadastrar retornam Result (Ok com Usuario ou Falha com mensagem).
//  Validações delegadas a Validadores (funções puras).


import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../core/validadores.dart';
import '../models/usuario.dart';
import '../repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final _repo = AuthRepository();
  Usuario? _usuario;

  Usuario? get usuario => _usuario;
  bool get autenticado => _usuario != null;

  //Validações (funções puras) 

  String? validarNome(String? v)  => Validadores.nome(v);
  String? validarEmail(String? v) => Validadores.email(v);
  String? validarSenha(String? v) => Validadores.senha(v);
  String? validarConfirmar(String? v, String senha) =>
      Validadores.confirmar(v, senha);

  //Autenticação

  Future<Result<Usuario>> entrar(String email, String senha) async {
    final r = await _repo.entrar(email, senha);
    if (r is Ok<Usuario>) {
      _usuario = r.value;
      notifyListeners();
    }
    return r;
  }

  Future<Result<Usuario>> cadastrar(
      String nome, String email, String senha) async {
    final r = await _repo.cadastrar(nome, email, senha);
    if (r is Ok<Usuario>) {
      _usuario = r.value;
      notifyListeners();
    }
    return r;
  }

  Future<void> sair() async {
    await _repo.sair();
    _usuario = null;
    notifyListeners();
  }

  /// Restaura a sessão anterior (auto-login via Firebase). Retorna 'true' se
  /// havia um usuário autenticado.
  Future<bool> carregarSessaoAtiva() async {
    _usuario = _repo.usuarioAtual;
    if (_usuario != null) notifyListeners();
    return _usuario != null;
  }

  Future<Result<void>> excluirConta() async {
    final r = await _repo.excluirConta();
    if (r is Ok<void>) {
      _usuario = null;
      notifyListeners();
    }
    return r;
  }
}
