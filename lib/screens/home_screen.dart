import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/beliscada.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'settings_screen.dart';
import 'exames_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  Beliscada? _ultima;
  int _intervalo = 7;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final ultima = await _storage.getUltimaBeliscada();
    final intervalo = await _storage.getIntervalo();

    setState(() {
      _ultima = ultima;
      _intervalo = intervalo;
      _carregando = false;
    });

    _atualizarNotificacao();
  }

  Future<void> _atualizarNotificacao() async {
    final status = _calcularStatus();
    await NotificationService.agendarNotificacaoDiaria(
      titulo: 'Belisquei?',
      corpo: status['mensagem'],
    );
  }

  Map<String, dynamic> _calcularStatus() {
    if (_ultima == null) {
      return {
        'pode': true,
        'diasRestantes': 0,
        'mensagem': 'Você ainda não registrou nenhuma besteira. Pode beliscar!',
      };
    }

    final diasPassados = DateTime.now().difference(_ultima!.data).inDays;
    final diasRestantes = _intervalo - diasPassados;

    if (diasRestantes <= 0) {
      return {
        'pode': true,
        'diasRestantes': 0,
        'mensagem': 'Já pode beliscar de novo! 🎉',
      };
    }

    return {
      'pode': false,
      'diasRestantes': diasRestantes,
      'mensagem': 'Ainda faltam $diasRestantes dia(s) para poder beliscar.',
    };
  }

  Future<void> _registrarBeliscada() async {
    final controller = TextEditingController();

    final oQueComeu = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('O que você comeu?'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Ex: pizza, chocolate, hambúrguer...',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (oQueComeu != null && oQueComeu.isNotEmpty) {
      final beliscada = Beliscada(
        data: DateTime.now(),
        oQueComeu: oQueComeu,
      );
      await _storage.salvarBeliscada(beliscada);
      await _carregarDados();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrado: $oQueComeu'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = _calcularStatus();
    final pode = status['pode'] as bool;
    final diasRestantes = status['diasRestantes'] as int;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        title: Text(
          'Belisquei?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.biotech_outlined),
            tooltip: 'Exames',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExamesScreen()),
              );
            },
          ),
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _carregarDados();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Card de status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: pode ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (pode ? Colors.green : Colors.red).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      pode ? Icons.check_circle_outline : Icons.timer_outlined,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pode ? 'Pode beliscar!' : 'Ainda não pode',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status['mensagem'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    if (!pode) ...[
                      const SizedBox(height: 16),
                      Text(
                        '$diasRestantes',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        diasRestantes == 1 ? 'dia restante' : 'dias restantes',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Última beliscada
              if (_ultima != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Última besteira',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ultima!.oQueComeu,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat("dd/MM/yyyy 'às' HH:mm").format(_ultima!.data),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Botão principal
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: _registrarBeliscada,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Belisquei!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}