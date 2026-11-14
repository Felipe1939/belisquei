import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/exame_sangue.dart';
import '../services/storage_service.dart';

class ExameSangueScreen extends StatefulWidget {
  final ExameSangue? exame; // null = novo exame

  const ExameSangueScreen({super.key, this.exame});

  @override
  State<ExameSangueScreen> createState() => _ExameSangueScreenState();
}

class _ExameSangueScreenState extends State<ExameSangueScreen> {
  static const _laranja = Color(0xFFFF6B35);
  static const _chavesColesterol = [
    'colesterol_total',
    'hdl',
    'ldl',
    'triglicerides',
  ];

  final StorageService _storage = StorageService();
  final Map<String, TextEditingController> _controllers = {};
  late DateTime _data;

  @override
  void initState() {
    super.initState();
    final exame = widget.exame;
    _data = exame?.data ?? DateTime.now();

    for (final secao in secoesSangue) {
      for (final campo in secao.campos) {
        final valor = exame?.valores[campo.chave];
        // Valores calculados não são preenchidos: assim são recalculados
        final eraCalculado = exame?.calculados.contains(campo.chave) ?? false;
        _controllers[campo.chave] = TextEditingController(
          text: (valor != null && !eraCalculado) ? formatarValor(valor) : '',
        );
      }
    }

    // Atualiza a prévia do cálculo enquanto digita
    for (final chave in _chavesColesterol) {
      _controllers[chave]!.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _ler(String chave) {
    final texto = _controllers[chave]!.text.trim().replaceAll(',', '.');
    if (texto.isEmpty) return null;
    return double.tryParse(texto);
  }

  ResultadoCalculo _calcular() {
    return calcularColesterol(
      ct: _ler('colesterol_total'),
      hdl: _ler('hdl'),
      ldl: _ler('ldl'),
      tg: _ler('triglicerides'),
    );
  }

  String _rotulo(String chave) {
    for (final s in secoesSangue) {
      for (final c in s.campos) {
        if (c.chave == chave) return c.rotulo;
      }
    }
    return chave;
  }

  Future<void> _escolherData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  void _aviso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _salvar() async {
    final valores = <String, double>{};

    for (final secao in secoesSangue) {
      for (final campo in secao.campos) {
        final texto = _controllers[campo.chave]!.text.trim();
        if (texto.isEmpty) continue;

        final v = _ler(campo.chave);
        if (v == null || v < 0) {
          _aviso('Valor inválido em "${campo.rotulo}"');
          return;
        }
        valores[campo.chave] = v;
      }
    }

    // Calcula o colesterol que ficou faltando (se for só um)
    final calculados = <String>[];
    final calculo = _calcular();

    if (calculo.erro != null) {
      _aviso(calculo.erro!);
      return;
    }
    if (calculo.chave != null && calculo.valor != null) {
      valores[calculo.chave!] = calculo.valor!;
      calculados.add(calculo.chave!);
    }

    if (valores.isEmpty) {
      _aviso('Preencha pelo menos um valor');
      return;
    }

    final exame = ExameSangue(
      id: widget.exame?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      data: _data,
      valores: valores,
      calculados: calculados,
    );

    await _storage.salvarExameSangue(exame);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text(
          'Exame de sangue',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  _seletorData(),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha só o que estiver no seu exame.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final secao in secoesSangue) _secao(secao),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _salvar,
                  style: FilledButton.styleFrom(
                    backgroundColor: _laranja,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Salvar exame',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seletorData() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _escolherData,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: _laranja),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Data do exame',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(_data),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secao(SecaoExame secao) {
    final ehColesterol = secao.titulo == 'Colesterol';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(secao.icone, color: _laranja),
              const SizedBox(width: 8),
              Text(
                secao.titulo,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (ehColesterol) ...[
            const SizedBox(height: 6),
            Text(
              'Seu exame não trouxe um dos valores? Deixe só ele em branco '
              'que o app calcula.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 14),
          for (final campo in secao.campos) ...[
            _campoTexto(campo),
            const SizedBox(height: 12),
          ],
          if (ehColesterol) _previaCalculo(),
        ],
      ),
    );
  }

  Widget _campoTexto(CampoExame campo) {
    return TextField(
      controller: _controllers[campo.chave],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,\.]'))],
      decoration: InputDecoration(
        labelText: campo.rotulo,
        suffixText: campo.unidade,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _previaCalculo() {
    final calculo = _calcular();
    if (calculo.chave == null) return const SizedBox.shrink();

    final erro = calculo.erro != null;
    final texto = erro
        ? calculo.erro!
        : '${_rotulo(calculo.chave!)} calculado: '
            '${formatarValor(calculo.valor!)} mg/dL';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: erro ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: erro ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            erro ? Icons.warning_amber_rounded : Icons.calculate_outlined,
            color: erro ? Colors.red.shade700 : Colors.green.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}