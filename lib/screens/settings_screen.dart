import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  int _intervalo = 7;
  final TextEditingController _customController = TextEditingController();
  bool _usandoCustom = false;

  final List<int> _opcoesFixas = [3, 5, 7, 10, 15, 30];

  @override
  void initState() {
    super.initState();
    _carregarIntervalo();
  }

  Future<void> _carregarIntervalo() async {
    final intervalo = await _storage.getIntervalo();
    setState(() {
      _intervalo = intervalo;
      if (!_opcoesFixas.contains(intervalo)) {
        _usandoCustom = true;
        _customController.text = intervalo.toString();
      }
    });
  }

  Future<void> _salvarIntervalo(int dias) async {
    await _storage.setIntervalo(dias);
    setState(() {
      _intervalo = dias;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Intervalo salvo: $dias dias'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text(
          'Configurações',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Intervalo entre besteiras',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'De quantos em quantos dias você pode beliscar?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Opções fixas
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _opcoesFixas.map((dias) {
              final selecionado = !_usandoCustom && _intervalo == dias;
              return ChoiceChip(
                label: Text('$dias dias'),
                selected: selecionado,
                onSelected: (_) {
                  setState(() {
                    _usandoCustom = false;
                    _customController.clear();
                  });
                  _salvarIntervalo(dias);
                },
                selectedColor: const Color(0xFFFF6B35),
                labelStyle: TextStyle(
                  color: selecionado ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Opção personalizada
          Text(
            'Ou digite um valor personalizado:',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ex: 12',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _usandoCustom = value.isNotEmpty;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  final dias = int.tryParse(_customController.text);
                  if (dias != null && dias > 0) {
                    _salvarIntervalo(dias);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Digite um número válido'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                child: const Text('Salvar'),
              ),
            ],
          ),

          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),

          // Informação atual
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFFF6B35)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Intervalo atual: $_intervalo dias',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}