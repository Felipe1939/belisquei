import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/beliscada.dart';

class StorageService {
  static const _keyIntervalo = 'intervalo_dias';
  static const _keyUltimaBeliscada = 'ultima_beliscada';
  static const _keyHistorico = 'historico';

  Future<int> getIntervalo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyIntervalo) ?? 7; // padrão 7 dias
  }

  Future<void> setIntervalo(int dias) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIntervalo, dias);
  }

  Future<Beliscada?> getUltimaBeliscada() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyUltimaBeliscada);
    if (json == null) return null;
    return Beliscada.fromJson(jsonDecode(json));
  }

  Future<void> salvarBeliscada(Beliscada beliscada) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUltimaBeliscada, jsonEncode(beliscada.toJson()));

    // Também salva no histórico
    final historico = await getHistorico();
    historico.insert(0, beliscada);
    await prefs.setString(
      _keyHistorico,
      jsonEncode(historico.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<Beliscada>> getHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyHistorico);
    if (json == null) return [];
    final List list = jsonDecode(json);
    return list.map((e) => Beliscada.fromJson(e)).toList();
  }
}