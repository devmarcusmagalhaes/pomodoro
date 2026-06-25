// lib/models/usuario.dart

// MUDANÇAS DA PARTE 3:
//    Modelo reflete o usuário do Firebase Authentication: identificado por
//   'uid', com 'nome' (displayName) e 'email'.
//    A senha NÃO é mais responsabilidade do app: o Firebase Auth cuida do
//    armazenamento seguro no servidor. Removido `senhaHash`.


class Usuario {
  final String uid;
  final String nome;
  final String email;

  const Usuario({
    required this.uid,
    required this.nome,
    required this.email,
  });

  /// Serialização usada para o documento de perfil no Firestore.
  Map<String, dynamic> toMap() => {
        'uid'  : uid,
        'nome' : nome,
        'email': email,
      };

  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
        uid  : map['uid']   as String,
        nome : map['nome']  as String? ?? '',
        email: map['email'] as String? ?? '',
      );
}
