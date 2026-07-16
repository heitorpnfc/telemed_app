class Bula {
  final int idProduto;
  final String numeroRegistro;
  final String nomeProduto;
  final String razaoSocial;
  final String? idBulaPacienteProtegido;

  Bula({
    required this.idProduto,
    required this.numeroRegistro,
    required this.nomeProduto,
    required this.razaoSocial,
    this.idBulaPacienteProtegido,
  });

  factory Bula.fromJson(Map<String, dynamic> json) {
    return Bula(
      idProduto: json['idProduto'] ?? 0,
      numeroRegistro: json['numeroRegistro'] ?? '',
      nomeProduto: json['nomeProduto'] ?? 'Sem nome',
      razaoSocial: json['razaoSocial'] ?? 'Fabricante desconhecido',
      idBulaPacienteProtegido: json['idBulaPacienteProtegido'],
    );
  }
}