import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/panier_ligne.dart';

class ServicePanierLocal {
  static final ServicePanierLocal _instance = ServicePanierLocal._internal();
  factory ServicePanierLocal() => _instance;
  ServicePanierLocal._internal();

  static const _key = 'panier_v1';

  final ValueNotifier<List<PanierLigne>> panier = ValueNotifier<List<PanierLigne>>([]);

  bool _initialise = false;

  Future<void> initialiser() async {
    if (_initialise) return;
    _initialise = true;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      panier.value = const [];
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      final list = (decoded as List)
          .cast<Map<String, dynamic>>()
          .map(PanierLigne.fromJson)
          .toList(growable: false);
      panier.value = list;
    } catch (_) {
      // Si données corrompues, on repart proprement.
      panier.value = const [];
      await prefs.remove(_key);
    }
  }

  int get total => panier.value.fold(0, (sum, item) => sum + item.total);

  int get nombreArticles =>
      panier.value.fold(0, (sum, item) => sum + item.quantite);

  Future<void> vider() async {
    panier.value = const [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> ajouter({
    required PanierLigne ligne,
  }) async {
    final items = [...panier.value];
    final idx = items.indexWhere((e) => e.cle == ligne.cle);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantite: items[idx].quantite + ligne.quantite);
    } else {
      items.add(ligne);
    }
    await _sauvegarder(items);
  }

  Future<void> supprimer(String cle) async {
    final items = panier.value.where((e) => e.cle != cle).toList(growable: false);
    await _sauvegarder(items);
  }

  Future<void> setQuantite(String cle, int quantite) async {
    final q = quantite.clamp(1, 999);
    final items = [...panier.value];
    final idx = items.indexWhere((e) => e.cle == cle);
    if (idx < 0) return;
    items[idx] = items[idx].copyWith(quantite: q);
    await _sauvegarder(items);
  }

  Future<void> incrementer(String cle) async {
    final items = [...panier.value];
    final idx = items.indexWhere((e) => e.cle == cle);
    if (idx < 0) return;
    items[idx] = items[idx].copyWith(quantite: items[idx].quantite + 1);
    await _sauvegarder(items);
  }

  Future<void> decrementer(String cle) async {
    final items = [...panier.value];
    final idx = items.indexWhere((e) => e.cle == cle);
    if (idx < 0) return;
    final next = items[idx].quantite - 1;
    if (next <= 0) {
      items.removeAt(idx);
    } else {
      items[idx] = items[idx].copyWith(quantite: next);
    }
    await _sauvegarder(items);
  }

  Future<void> _sauvegarder(List<PanierLigne> items) async {
    panier.value = List.unmodifiable(items);
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList(growable: false));
    await prefs.setString(_key, raw);
  }
}

