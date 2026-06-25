// lib/services/firebase_auth_service.dart  ← NOVO na Parte 3

// Wrapper fino sobre o FirebaseAuth. Isola o pacote do Firebase do resto do
// app: apenas esta classe conhece `FirebaseAuth`, o que facilita testes e uma
// eventual troca de provedor de autenticação.

// O acesso a 'FirebaseAuth.instance' é feito por getter (lazy) para que a
// construção da classe não exija o Firebase inicializado (importante em testes
// de unidade que não sobem o Firebase).


import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Usuário autenticado no momento (ou `null`). O Firebase persiste a sessão
  /// automaticamente entre aberturas do app.
  User? get usuarioAtual => _auth.currentUser;

  /// Stream que emite a cada login/logout.
  Stream<User?> get mudancasDeAutenticacao => _auth.authStateChanges();

  Future<UserCredential> entrar(String email, String senha) =>
      _auth.signInWithEmailAndPassword(email: email, password: senha);

  Future<UserCredential> cadastrar(String email, String senha) =>
      _auth.createUserWithEmailAndPassword(email: email, password: senha);

  Future<void> atualizarNome(String nome) async =>
      _auth.currentUser?.updateDisplayName(nome);

  Future<void> sair() => _auth.signOut();

  /// Remove a conta do usuário autenticado do Firebase Auth.
  Future<void> excluirConta() async => _auth.currentUser?.delete();
}
