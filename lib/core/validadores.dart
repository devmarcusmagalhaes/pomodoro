// lib/core/validadores.dart

// Funções puras de validação de formulário (sem dependência de UI ou serviços).
// Centralizar aqui facilita o teste e o reúso entre telas.

// MUDANÇA DA PARTE 3: validação de e-mail substitui a de "login", pois o
// Firebase Authentication é baseado em e-mail/senha.


abstract final class Validadores {
  static String? nome(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nome é obrigatório.';
    if (v.trim().length < 3) return 'Mínimo 3 caracteres.';
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(v.trim())) {
      return 'Apenas letras.';
    }
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'E-mail é obrigatório.';
    final padrao = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!padrao.hasMatch(v.trim())) return 'E-mail inválido.';
    return null;
  }

  static String? senha(String? v) {
    if (v == null || v.isEmpty) return 'Senha é obrigatória.';
    if (v.length < 6) return 'Mínimo 6 caracteres.';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Inclua ao menos 1 número.';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Inclua ao menos 1 maiúscula.';
    return null;
  }

  static String? confirmar(String? v, String senhaOriginal) {
    if (v == null || v.isEmpty) return 'Confirme a senha.';
    if (v != senhaOriginal) return 'As senhas não coincidem.';
    return null;
  }
}
