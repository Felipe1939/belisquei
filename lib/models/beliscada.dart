class Beliscada {
  final DateTime data;
  final String oQueComeu;

  Beliscada({
    required this.data,
    required this.oQueComeu,
  });

  Map<String, dynamic> toJson() => {
        'data': data.toIso8601String(),
        'oQueComeu': oQueComeu,
      };

  factory Beliscada.fromJson(Map<String, dynamic> json) {
    return Beliscada(
      data: DateTime.parse(json['data']),
      oQueComeu: json['oQueComeu'],
    );
  }
}