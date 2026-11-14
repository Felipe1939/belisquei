import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/exame_sangue.dart';
import '../services/storage_service.dart';
import 'exame_sangue_screen.dart';

// 👇 Se os nomes dos seus ícones forem outros, troque aqui
const String _iconeSangue = 'assets/images/icone_sangue.png';
const String _iconeFezes = 'assets/images/icone_fezes.png';
const String _iconeUrina = 'assets/images/icone_urina.png';

enum TipoExame { sangue, fezes, urina }

class ExamesScreen extends StatefulWidget {
  const ExamesScreen({super.key});

  @override
  State<ExamesScreen> createState() => _ExamesScreenState();
}

class _ExamesScreenState extends State<ExamesScreen> {
  static const _laranja = Color(0xFFFF6B35);

  final StorageService _storage = StorageService();
  List<ExameSangue> _exames = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final exames = await _storage.getExamesSangue();
    if (!mounted) return;
    setState(() {
      _exames = exames;
      _carregando = false;
    });
  }

  Future<void> _inserirExame() async {
    final selecionados = await showDialog<Set<TipoExame>>(
      context: context,
      builder: (_) => const _DialogTipoExame(),
    );

    if (selecionados == null || selecionados.isEmpty || !mounted) return;

    if (selecionados.contains(TipoExame.fezes) ||
        selecionados.contains(TipoExame.urina)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exames de fezes e urina chegam em breve!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (selecionados.contains(TipoExame.sangue)) {
      await _abrirExameSangue();
    }
  }

  Future<void> _abrirExameSangue([ExameSangue? exame]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExameSangueScreen(exame: exame)),
    );
    _carregar();
  }

  Future<void> _excluir(ExameSangue exame) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir exame?'),
        content: Text(
          'O exame de ${DateFormat('dd/MM/yyyy').format(exame.data)} '
          'será removido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _storage.excluirExameSangue(exame.id);
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text(
          'Exames',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            children: [
              Expanded(
                child: _carregando
                    ? const Center(child: CircularProgressIndicator())
                    : _exames.isEmpty
                        ? _estadoVazio()
                        : ListView.separated(
                            itemCount: _exames.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) => _cardExame(_exames[i]),
                          ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton.icon(
                  onPressed: _inserirExame,
                  icon: const Icon(Icons.add),
                  style: FilledButton.styleFrom(
                    backgroundColor: _laranja,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  label: Text(
                    'Inserir exame',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.biotech_outlined, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum exame ainda',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toque em "Inserir exame" para começar.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _cardExame(ExameSangue exame) {
    // Resumo com os principais valores, se existirem
    final resumo = <String, String>{
      'Col. total': 'colesterol_total',
      'LDL': 'ldl',
      'HDL': 'hdl',
      'Glicose': 'glicemia_jejum',
    };

    final chips = <Widget>[];
    resumo.forEach((rotulo, chave) {
      final v = exame.valores[chave];
      if (v != null) {
        chips.add(_chip('$rotulo ${formatarValor(v)}'));
      }
    });

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _abrirExameSangue(exame),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _imagem(_iconeSangue, Icons.bloodtype, 44),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exame de sangue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(exame.data),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: chips),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.grey[600],
              onPressed: () => _excluir(exame),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Carrega a imagem do asset; se não achar, mostra um ícone padrão.
Widget _imagem(String caminho, IconData fallback, double tamanho) {
  return Image.asset(
    caminho,
    width: tamanho,
    height: tamanho,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => SizedBox(
      width: tamanho,
      height: tamanho,
      child: Icon(fallback, size: tamanho * 0.8, color: const Color(0xFFFF6B35)),
    ),
  );
}

// ───────────────────────── POP-UP ─────────────────────────

class _DialogTipoExame extends StatefulWidget {
  const _DialogTipoExame();

  @override
  State<_DialogTipoExame> createState() => _DialogTipoExameState();
}

class _DialogTipoExameState extends State<_DialogTipoExame> {
  final Set<TipoExame> _selecionados = {};

  void _alternar(TipoExame tipo) {
    setState(() {
      if (!_selecionados.add(tipo)) _selecionados.remove(tipo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Quais exames?',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Você pode escolher um ou mais.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _opcao(TipoExame.sangue, 'Sangue', _iconeSangue, Icons.bloodtype),
              const SizedBox(width: 8),
              _opcao(TipoExame.fezes, 'Fezes', _iconeFezes, Icons.science),
              const SizedBox(width: 8),
              _opcao(TipoExame.urina, 'Urina', _iconeUrina, Icons.water_drop),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selecionados.isEmpty
              ? null
              : () => Navigator.pop(context, _selecionados),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
          ),
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _opcao(
    TipoExame tipo,
    String rotulo,
    String caminho,
    IconData fallback,
  ) {
    final selecionado = _selecionados.contains(tipo);

    return Expanded(
      child: GestureDetector(
        onTap: () => _alternar(tipo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selecionado ? Colors.orange.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selecionado
                  ? const Color(0xFFFF6B35)
                  : Colors.grey.shade300,
              width: selecionado ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              _imagem(caminho, fallback, 52),
              const SizedBox(height: 8),
              Text(
                rotulo,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: selecionado ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}