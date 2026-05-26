import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/usuario.dart';
import 'db_service.dart';
import 'preferencias_service.dart';

class AuthService {
  final PreferenciasService _prefs = PreferenciasService();

  // Hash de senha 

  ///Converte uma senha em texto puro para SHA-256 hexadecimal (64 chars).
  //Exemplo: "Abc123" → "6ca13d52ca70c883e0f0bb101e425a89e8624de5..."
  String _hashSenha(String senha) =>
      sha256.convert(utf8.encode(senha)).toString();

  //Validações de formulário

  String? validarNome(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nome é obrigatório.';
    if (v.trim().length < 3) return 'Mínimo 3 caracteres.';
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(v.trim())) {
      return 'Apenas letras.';
    }
    return null;
  }

  String? validarLogin(String? v) {
    if (v == null || v.trim().isEmpty) return 'Login é obrigatório.';
    if (v.trim().length < 4) return 'Mínimo 4 caracteres.';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
      return 'Letras, números e _ apenas.';
    }
    return null;
  }

  String? validarSenha(String? v) {
    if (v == null || v.isEmpty) return 'Senha é obrigatória.';
    if (v.length < 6) return 'Mínimo 6 caracteres.';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Inclua ao menos 1 número.';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Inclua ao menos 1 maiúscula.';
    return null;
  }

  String? validarConfirmar(String? v, String senha) {
    if (v == null || v.isEmpty) return 'Confirme a senha.';
    if (v != senha) return 'As senhas não coincidem.';
    return null;
  }

  //Operações de autenticação

  bool loginEmUso(String login) => DbService.usuarios.containsKey(login);

  //Verifica credenciais e persiste a sessão ativa em SharedPreferences.
  //Retorna `null` se o login não existe ou a senha está incorreta.
  Future<Usuario?> entrar(String login, String senha) async {
    final raw = DbService.usuarios.get(login);
    if (raw == null) return null;

    final usuario = Usuario.fromMap(Map<String, dynamic>.from(raw as Map));
    if (usuario.senhaHash != _hashSenha(senha)) return null;

    await _prefs.gravarLoginAtivo(login);
    return usuario;
  }

  //Cria um novo usuário, persiste no banco e registra a sessão ativa.
  
  ///Lança [StateError] se o login já existir (defesa adicional contra race
  ///condition entre a checagem em [loginEmUso] e a gravação).
  Future<Usuario> cadastrar(String nome, String login, String senha) async {
    if (loginEmUso(login)) {
      throw StateError('Login já em uso.');
    }

    final novo = Usuario(
      nome     : nome,
      login    : login,
      senhaHash: _hashSenha(senha),
    );
    await DbService.usuarios.put(login, novo.toMap());
    await _prefs.gravarLoginAtivo(login);
    return novo;
  }

  //Remove o login ativo do SharedPreferences (logout).
  Future<void> sair() async => _prefs.limparLoginAtivo();

  //Tenta restaurar a sessão anterior (auto-login).
  //Se o login salvo aponta para um usuário inexistente, limpa o lixo.
  Future<Usuario?> carregarSessaoAtiva() async {
    final login = await _prefs.lerLoginAtivo();
    if (login == null) return null;

    final raw = DbService.usuarios.get(login);
    if (raw == null) {
      await _prefs.limparLoginAtivo();
      return null;
    }

    return Usuario.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  //Apaga o usuário do banco e finaliza a sessão.
  //A limpeza das sessões do usuário deve ser feita pelo chamador
  //(ver `SessaoService.limpar`).
  Future<void> excluirConta(String login) async {
    await DbService.usuarios.delete(login);
    await _prefs.limparLoginAtivo();
  }
}
