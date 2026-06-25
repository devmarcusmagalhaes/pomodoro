// lib/repositories/sessao_repository.dart  ← NOVO na Parte 3

// Repositório OFFLINE-FIRST das sessões de estudo. Combina:
//   - Firestore (fonte da verdade, na nuvem, sincroniza entre dispositivos)
//   - Hive (cache local, leitura instantânea e fallback quando offline)

// Estratégia:
//   • carregar(): tenta a nuvem; em caso de sucesso espelha no Hive; se falhar
//     (offline/erro), devolve o cache local.
//   • adicionar(): grava no Hive (garantia imediata) e dispara a escrita no
//     Firestore. O Firestore tem persistência offline própria, então a escrita
//     é enfileirada e sincronizada sozinha quando a conexão voltar.


import '../models/sessao_estudo.dart';
import '../services/firestore_service.dart';
import '../services/sessao_service.dart';

class SessaoRepository {
  final _firestore = FirestoreService();
  final _cacheLocal = SessaoService(); // Hive

  /// Carrega as sessões do usuário (nuvem com fallback para o cache local).
  Future<List<SessaoEstudo>> carregar(String uid) async {
    try {
      final remotas = await _firestore.carregarSessoes(uid);
      await _cacheLocal.salvar(uid, remotas); // espelha no Hive
      return remotas;
    } catch (_) {
      // Offline ou erro de rede: usa o cache local (offline-first).
      return _cacheLocal.carregar(uid);
    }
  }

  /// Adiciona uma sessão: grava no cache local e dispara a escrita na nuvem.
  Future<void> adicionar(String uid, SessaoEstudo sessao) async {
    // Cache local primeiro: garante o dado mesmo sem internet.
    await _cacheLocal.adicionar(uid, sessao);

    // Não aguardamos o Firestore: a persistência offline dele enfileira a
    // escrita e sincroniza quando houver conexão. Erros são silenciados pois
    // o dado já está garantido localmente.
    _firestore.adicionarSessao(uid, sessao).catchError((_) {});
  }
}
