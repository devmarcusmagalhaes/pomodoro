// lib/repositories/auth_repository.dart  ← NOVO na Parte 3

// Orquestra a autenticação: combina o Firebase Auth (credenciais) com o
// Firestore (perfil/nome). Converte as exceções do Firebase em mensagens
// amigáveis em português via Result, sem vazar detalhes para a UI.


import 'package:firebase_auth/firebase_auth.dart';

import '../core/result.dart';
import '../models/usuario.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

class AuthRepository {
  final _authService = FirebaseAuthService();
  final _firestore = FirestoreService();

  /// Usuário autenticado atual, montado a partir do Firebase Auth.
  Usuario? get usuarioAtual {
    final u = _authService.usuarioAtual;
    if (u == null) return null;
    return Usuario(
      uid  : u.uid,
      nome : u.displayName ?? '',
      email: u.email ?? '',
    );
  }

  bool get temSessaoAtiva => _authService.usuarioAtual != null;

  Future<Result<Usuario>> entrar(String email, String senha) async {
    try {
      final cred = await _authService.entrar(email.trim(), senha);
      final user = cred.user!;
      final nome = await _firestore.lerNome(user.uid) ?? user.displayName ?? '';
      return Ok(Usuario(uid: user.uid, nome: nome, email: user.email ?? email));
    } on FirebaseAuthException catch (e) {
      return Falha(_traduzir(e));
    } catch (e) {
      return Falha('Erro inesperado ao entrar.', e);
    }
  }

  Future<Result<Usuario>> cadastrar(
      String nome, String email, String senha) async {
    try {
      final cred = await _authService.cadastrar(email.trim(), senha);
      final user = cred.user!;
      await _authService.atualizarNome(nome.trim());
      await _firestore.salvarPerfil(user.uid, nome.trim(), email.trim());
      return Ok(Usuario(uid: user.uid, nome: nome.trim(), email: email.trim()));
    } on FirebaseAuthException catch (e) {
      return Falha(_traduzir(e));
    } catch (e) {
      return Falha('Erro inesperado ao cadastrar.', e);
    }
  }

  Future<void> sair() => _authService.sair();

  /// Exclui a conta: apaga dados no Firestore e remove do Firebase Auth.
  Future<Result<void>> excluirConta() async {
    final uid = _authService.usuarioAtual?.uid;
    if (uid == null) return const Falha('Nenhum usuário autenticado.');
    try {
      await _firestore.excluirDados(uid);
      await _authService.excluirConta();
      return const Ok(null);
    } on FirebaseAuthException catch (e) {
      return Falha(_traduzir(e));
    } catch (e) {
      return Falha('Erro ao excluir a conta.', e);
    }
  }

  /// Traduz os códigos de erro do Firebase Auth para mensagens claras.
  String _traduzir(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'Senha muito fraca.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'requires-recent-login':
        return 'Faça login novamente para concluir esta ação.';
      default:
        return 'Falha na autenticação (${e.code}).';
    }
  }
}
