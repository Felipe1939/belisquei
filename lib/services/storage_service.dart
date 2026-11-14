import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/beliscada.dart';
import '../models/exame_sangue.dart';
static const _keyExamesSangue = 'exames_sangue';

class StorageService {
  static const _keyIntervalo = 'intervalo_dias';
  static const _keyUltimaBeliscada = 'ultima_beliscada';
  static const _keyHistorico = 'historico';

  Future<List<ExameSangue>> getExamesSangue() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyExamesSangue);
    if (json == null) return [];
    final List list = jsonDecode(json);
    final exames = list.map((e) => ExameSangue.fromJson(e)).toList();
    exames.sort((a, b) => b.data.compareTo(a.data));
    return exames;
  }

  Future<void> _gravarExamesSangue(List<ExameSangue> exames) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyExamesSangue,
      jsonEncode(exames.map((e) => e.toJson()).toList()),
    );
  }

  /// Salva um exame novo ou atualiza um existente (mesmo id).
  Future<void> salvarExameSangue(ExameSangue exame) async {
    final exames = await getExamesSangue();
    final index = exames.indexWhere((e) => e.id == exame.id);
    if (index >= 0) {
      exames[index] = exame;
    } else {
      exames.add(exame);
    }
    await _gravarExamesSangue(exames);
  }

  Future<void> excluirExameSangue(String id) async {
    final exames = await getExamesSangue();
    exames.removeWhere((e) => e.id == id);
    await _gravarExamesSangue(exames);
  }

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