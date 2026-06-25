// lib/services/firestore_service.dart  ← NOVO na Parte 3

// Wrapper sobre o Cloud Firestore. Modela os dados assim:

//   usuarios/{uid}                       → { nome, email, criadoEm }
//   usuarios/{uid}/sessoes/{sessaoId}    → { data, minutos, latitude, ... }

// As sessões ficam numa subcoleção do usuário, garantindo isolamento natural
// por uid (as regras de segurança do Firestore reforçam isso no servidor).

// 'FirebaseFirestore.instance' é acessado por getter (lazy) para não exigir o
// Firebase inicializado na construção da classe.


import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sessao_estudo.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _usuarioRef(String uid) =>
      _db.collection('usuarios').doc(uid);

  CollectionReference<Map<String, dynamic>> _sessoesRef(String uid) =>
      _usuarioRef(uid).collection('sessoes');

  // Perfil

  Future<void> salvarPerfil(String uid, String nome, String email) =>
      _usuarioRef(uid).set({
        'nome'    : nome,
        'email'   : email,
        'criadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<String?> lerNome(String uid) async {
    final doc = await _usuarioRef(uid).get();
    return doc.data()?['nome'] as String?;
  }

  //Sessões

  Future<void> adicionarSessao(String uid, SessaoEstudo sessao) =>
      _sessoesRef(uid).add(sessao.toMap());

  Future<List<SessaoEstudo>> carregarSessoes(String uid) async {
    final snap = await _sessoesRef(uid).orderBy('data').get();
    return snap.docs.map((d) => SessaoEstudo.fromMap(d.data())).toList();
  }

  //Exclusão de conta 

  /// Apaga todas as sessões e o documento de perfil do usuário.
  Future<void> excluirDados(String uid) async {
    final snap = await _sessoesRef(uid).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
    await _usuarioRef(uid).delete();
  }
}
