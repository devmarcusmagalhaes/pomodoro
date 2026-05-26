// lib/services/sessao_service.dart

//Camada de persistência das sessões de estudo. Cada usuário tem sua lista
//isolada por chave (= login) no Hive.

import '../models/sessao_estudo.dart';
import 'db_service.dart';

class SessaoService {
  ///Carrega todas as sessões salvas do [login] informado.
  //Retorna lista vazia se o usuário ainda não possui sessões.
  Future<List<SessaoEstudo>> carregar(String login) async {
    final raw = DbService.sessoes.get(login);
    if (raw == null) return [];

    ///Hive retorna List<dynamic> de Maps; precisamos do cast explícito.
    return (raw as List)
        .map((m) => SessaoEstudo.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  ///Grava a lista completa de [sessoes] do usuário no banco.
  Future<void> salvar(String login, List<SessaoEstudo> sessoes) async {
    final lista = sessoes.map((s) => s.toMap()).toList();
    await DbService.sessoes.put(login, lista);

      DbService.imprimirRaioXDoBanco();
  }

  ///Adiciona uma única [nova] sessão ao banco, preservando as anteriores.
  Future<void> adicionar(String login, SessaoEstudo nova) async {
    final existentes = await carregar(login);
    existentes.add(nova);
    await salvar(login, existentes);
  }

  /// Apaga todas as sessões do [login]. Usado quando a conta é excluída.
  Future<void> limpar(String login) async {
    await DbService.sessoes.delete(login);
  }
}
