class Usuario {
  final String nome;
  final String login;
  final String senhaHash; // SHA-256 hexadecimal da senha original

  const Usuario({
    required this.nome,
    required this.login,
    required this.senhaHash,
  });

  //Serializa o usuário para um Map compatível com o Hive.
  Map<String, dynamic> toMap() => {
        'nome'     : nome,
        'login'    : login,
        'senhaHash': senhaHash,
      };

  //Reconstrói um [Usuario] a partir de um Map lido do Hive.
  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
        nome     : map['nome']      as String,
        login    : map['login']     as String,
        senhaHash: map['senhaHash'] as String,
      );
}
