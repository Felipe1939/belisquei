import 'package:flutter/material.dart';

class CampoExame {
  final String chave;
  final String rotulo;
  final String unidade;

  const CampoExame(this.chave, this.rotulo, this.unidade);
}

class SecaoExame {
  final String titulo;
  final IconData icone;
  final List<CampoExame> campos;

  const SecaoExame(this.titulo, this.icone, this.campos);
}

const List<SecaoExame> secoesSangue = [
  SecaoExame('Colesterol', Icons.favorite_border, [
    CampoExame('colesterol_total', 'Colesterol total', 'mg/dL'),
    CampoExame('hdl', 'HDL', 'mg/dL'),
    CampoExame('ldl', 'LDL', 'mg/dL'),
    CampoExame('triglicerides', 'Triglicerídeos', 'mg/dL'),
  ]),
  SecaoExame('Glicose', Icons.water_drop_outlined, [
    CampoExame('glicemia_jejum', 'Glicemia de jejum', 'mg/dL'),
    CampoExame('hba1c', 'Hemoglobina glicada (HbA1c)', '%'),
    CampoExame('insulina', 'Insulina de jejum', 'µUI/mL'),
  ]),
  SecaoExame('Função renal', Icons.science_outlined, [
    CampoExame('creatinina', 'Creatinina', 'mg/dL'),
    CampoExame('ureia', 'Ureia', 'mg/dL'),
    CampoExame('acido_urico', 'Ácido úrico', 'mg/dL'),
  ]),
  SecaoExame('Fígado', Icons.health_and_safety_outlined, [
    CampoExame('tgo', 'TGO (AST)', 'U/L'),
    CampoExame('tgp', 'TGP (ALT)', 'U/L'),
    CampoExame('gama_gt', 'Gama GT', 'U/L'),
  ]),
  SecaoExame('Outros', Icons.add_chart_outlined, [
    CampoExame('hemoglobina', 'Hemoglobina', 'g/dL'),
    CampoExame('tsh', 'TSH', 'mUI/L'),
    CampoExame('vitamina_d', 'Vitamina D', 'ng/mL'),
    CampoExame('vitamina_b12', 'Vitamina B12', 'pg/mL'),
    CampoExame('ferritina', 'Ferritina', 'ng/mL'),
  ]),
];

/// Formata o número sem ".0" sobrando e com vírgula (padrão BR).
String formatarValor(double v) {
  final texto = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  return texto.replaceAll('.', ',');
}

class ExameSangue {
  final String id;
  final DateTime data;
  final Map<String, double> valores;

  /// Chaves dos valores que foram calculados (e não digitados).
  final List<String> calculados;

  ExameSangue({
    required this.id,
    required this.data,
    required this.valores,
    this.calculados = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toIso8601String(),
        'valores': valores,
        'calculados': calculados,
      };

  factory ExameSangue.fromJson(Map<String, dynamic> json) {
    return ExameSangue(
      id: json['id'],
      data: DateTime.parse(json['data']),
      valores: (json['valores'] as Map)
          .map((k, v) => MapEntry(k as String, (v as num).toDouble())),
      calculados: List<String>.from(json['calculados'] ?? []),
    );
  }
}

class ResultadoCalculo {
  final String? chave;
  final double? valor;
  final String? erro;

  const ResultadoCalculo({this.chave, this.valor, this.erro});
}

/// Se exatamente UM dos 4 valores estiver faltando, calcula ele
/// usando a fórmula de Friedewald (VLDL = triglicerídeos / 5):
///   CT = HDL + LDL + TG/5
/// Só vale para triglicerídeos abaixo de 400 mg/dL.
ResultadoCalculo calcularColesterol({
  double? ct,
  double? hdl,
  double? ldl,
  double? tg,
}) {
  final faltando = <String>[
    if (ct == null) 'colesterol_total',
    if (hdl == null) 'hdl',
    if (ldl == null) 'ldl',
    if (tg == null) 'triglicerides',
  ];

  if (faltando.length != 1) return const ResultadoCalculo();

  final chave = faltando.first;

  if (chave != 'triglicerides' && tg! >= 400) {
    return ResultadoCalculo(
      chave: chave,
      erro: 'Com triglicerídeos ≥ 400 mg/dL a fórmula não é confiável. '
          'Preencha o valor que está faltando.',
    );
  }

  final valor = switch (chave) {
    'ldl' => ct! - hdl! - tg! / 5,
    'hdl' => ct! - ldl! - tg! / 5,
    'colesterol_total' => hdl! + ldl! + tg! / 5,
    _ => (ct! - hdl! - ldl!) * 5, // triglicerídeos
  };

  if (valor <= 0) {
    return ResultadoCalculo(
      chave: chave,
      erro: 'Os valores informados não fecham a conta. Confira os números.',
    );
  }

  return ResultadoCalculo(
    chave: chave,
    valor: double.parse(valor.toStringAsFixed(1)),
  );
}