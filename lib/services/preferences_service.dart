import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyNomeUsuario = 'key_nome_usuario';
  static const String _keyModoEscuro = 'key_modo_escuro';
  static const String _keyUltimoAcesso = 'key_ultimo_acesso';
  static const String _keyTarefas = 'key_tarefas';

  static const String nomePadrao = 'Usuário Convidado';

  Future<void> salvarNomeUsuario(String nome) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNomeUsuario, nome);
  }

  Future<String> obterNomeUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNomeUsuario) ?? nomePadrao;
  }

  Future<void> salvarModoEscuro(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyModoEscuro, valor);
  }

  Future<bool> obterModoEscuro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyModoEscuro) ?? false;
  }

  // Desafio Básico: data/hora da última execução do app
  Future<void> registrarUltimoAcesso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUltimoAcesso, DateTime.now().toString());
  }

  Future<DateTime?> obterUltimoAcesso() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString(_keyUltimoAcesso);
    return valor == null ? null : DateTime.tryParse(valor);
  }

  // Desafio Avançado: lista de tarefas serializada como JSON em uma String
  Future<void> salvarTarefas(List<Map<String, dynamic>> tarefas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTarefas, jsonEncode(tarefas));
  }

  Future<List<Map<String, dynamic>>> obterTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyTarefas);
    if (json == null) return [];
    final lista = jsonDecode(json) as List<dynamic>;
    return lista.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  // Desafio Intermediário: remove todas as chaves salvas
  Future<void> limparTudo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
