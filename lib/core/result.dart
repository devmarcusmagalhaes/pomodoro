// lib/core/result.dart

// Tipo Result<T> para tratamento explícito de sucesso/falha sem exceções
// vazando para as camadas superiores. Usa `sealed class` (Dart 3) para
// permitir pattern matching exaustivo com `switch`.

// Uso típico:
//   final r = await servico.buscar();
//   switch (r) {
//     case Ok(:final value): usar(value);
//     case Falha(:final mensagem): mostrarErro(mensagem);
//   }


sealed class Result<T> {
  const Result();

  /// Atalho para checar sucesso sem `switch`.
  bool get sucesso => this is Ok<T>;

  /// Retorna o valor se [Ok], ou `null` se [Falha].
  T? get valorOuNulo => this is Ok<T> ? (this as Ok<T>).value : null;
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Falha<T> extends Result<T> {
  final String mensagem;
  final Object? erro;
  const Falha(this.mensagem, [this.erro]);
}
