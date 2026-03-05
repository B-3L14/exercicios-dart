class Usuario {
  final String id;
  final String nome_completo;
  final String email;
  final String telefone;
  final String? foto_perfil_url;
  final bool ativo;
  final DateTime criado_em;

  const Usuario({
    required this.id,
    required this.nome_completo,
    required this.email,
    required this.telefone,
    this.foto_perfil_url,
    required this.ativo,
    required this.criado_em,
  });

  String get dataIso8601 => criado_em.toIso8601String();

  Usuario.fromJson(Map<String, dynamic> json):
      id = json['id'] as String,
      nome_completo = json['nome_completo'] as String,
      email = json['email'] as String,
      telefone = json['telefone'] as String,
      foto_perfil_url = json['foto_perfil_url'] as String?,
      ativo = (json['ativo'] as bool),
      criado_em = DateTime.parse(json['criado_em']); 

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome_completo': nome_completo,
      'email': email,
      'telefone': telefone,
      if (foto_perfil_url != null) 'foto_perfil_url': foto_perfil_url,
      'ativo': ativo,
      'criado_em': dataIso8601, 
    };
  }

  Usuario copyWith({
    String? id,
    String? nome_completo,
    String? email,
    String? telefone,
    Object? foto_perfil_url = const Object(),
    bool? ativo,
    DateTime? criado_em,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome_completo: nome_completo ?? this.nome_completo,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      foto_perfil_url: foto_perfil_url == const Object() ? this.foto_perfil_url : foto_perfil_url as String?,
      ativo: ativo ?? this.ativo,
      criado_em: criado_em ?? this.criado_em,
    );
  }


  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Usuario && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Usuario{id: $id, nome_completo: $nome_completo, email: $email, telefone: $telefone, foto_perfil_url: $foto_perfil_url, ativo: $ativo, criado_em: $criado_em}';
  }
}

void main() {

  final json_recebido = {
  "id": "usr-4f8a",
  "nome_completo": "Ana Lima",
  "email": "ana.lima@exemplo.com",
  "telefone": "+5511999990000",
  "foto_perfil_url": null,
  "ativo": true,
  "criado_em": "2024-09-15T10:30:00Z"};

  final usuario1 = Usuario.fromJson(json_recebido);
  print(usuario1);

  final usuario2 = usuario1.copyWith(telefone: "+5511988887777");
  print(usuario2);

  print(usuario1 == usuario2);

  final json_usuario_2 = usuario2.toJson();
  print(json_usuario_2);
}