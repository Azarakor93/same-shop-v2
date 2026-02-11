// ===============================================
// 🎨 UTILS ICÔNES - MAPPING COMPLET
// ===============================================
// Fonction réutilisable pour convertir les icônes Material en emoji
// Basé sur la table categories réelle

import 'package:flutter/material.dart';

// ===============================================
// 🎨 UTILS - TRI FRANÇAIS (ACCENTS)
// ===============================================
int compareFrancais(String a, String b) {
  // Normalise accents français
  String normalize(String s) => s
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('û', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ç', 'c')
      .toLowerCase();

  return normalize(a).compareTo(normalize(b));
}

// ===============================================
// 🎨 UTILS - ICONS CATEGORIE
// ===============================================
String getIconeEmoji(String iconeCode) {
  final Map<String, String> mapping = {
    // Électronique & High-Tech
    'smartphone': '📱',
    'laptop': '💻',
    'computer': '🖥️',
    'tablet': '📱',
    'watch': '⌚',
    'headphones': '🎧',
    'camera': '📷',
    'photo_camera': '📷',
    'videocam': '📹',
    'tv': '📺',
    'radio': '📻',
    'speaker': '🔊',
    'mic': '🎤',
    'cable': '🔌',
    'battery_charging_full': '🔋',
    'power': '⚡',
    'solar_power': '☀️',
    'gps_fixed': '📍',
    'wifi': '📶',
    'print': '🖨️',
    'storage': '💾',
    'gamepad': '🎮',
    'stadia_controller': '🎮',
    'sports_esports': '🎮',
    'surround_sound': '🔊',
    'trip_origin': '⭕',

    // Mode & Vêtements
    'checkroom': '👔',
    'woman': '👗',
    'man': '🧔',
    'child_care': '👶',
    'hiking': '👟',
    'diamond': '💎',

    // Maison & Jardin
    'home': '🏠',
    'bed': '🛏️',
    'bathtub': '🛁',
    'crib': '🍼',
    'kitchen': '🍽️',
    'restaurant': '🍽️',
    'countertops': '🏠',
    'grass': '🌱',
    'yard': '🌳',
    'water': '💧',
    'build': '🔧',
    'settings': '⚙️',

    // Beauté & Santé
    'face': '💄',
    'brush': '🖌️',
    'content_cut': '✂️',
    'spa': '💆',
    'self_improvement': '🧘',
    'local_florist': '🌸',
    'health_and_safety': '🏥',
    'medical_services': '⚕️',
    'local_pharmacy': '💊',
    'medication': '💊',
    'clean_hands': '🧼',

    // Sport & Fitness
    'sports_soccer': '⚽',
    'sports_basketball': '🏀',
    'sports_tennis': '🎾',
    'sports_volleyball': '🏐',
    'fitness_center': '💪',
    'pool': '🏊',
    'directions_bike': '🚴',
    'directions_run': '🏃',
    'terrain': '⛰️',

    // Animaux
    'pets': '🐕',
    'flutter_dash': '🐦',
    'emoji_nature': '🦎',

    // Alimentation
    'fastfood': '🍔',
    'local_pizza': '🍕',
    'takeout_dining': '🥡',
    'local_drink': '🥤',
    'rice_bowl': '🍚',
    'soup_kitchen': '🍲',
    'egg': '🥚',
    'oil_barrel': '🛢️',

    // Auto & Moto
    'directions_car': '🚗',
    'two_wheeler': '🏍️',
    'electric_car': '⚡',
    'tire_repair': '🛞',

    // Services
    'handyman': '🛠️',
    'home_repair_service': '🔨',
    'cleaning_services': '🧹',
    'local_shipping': '🚚',
    'delivery_dining': '🛵',
    'school': '🎓',

    // Culture & Loisirs
    'palette': '🎨',
    'music_note': '🎵',
    'menu_book': '📚',
    'collections_bookmark': '📖',
    'piano': '🎹',
    'drum': '🥁',
    'code': '💻',

    // Shopping
    'shopping_cart': '🛒',
    'shopping_bag': '🛍️',
    'local_offer': '🏷️',

    // Divers
    'more_horiz': '⋯',
    'handmade': '✋',
    'local_hospital': '🏥',
    'baby_changing_station': '🍼',
    'airline_seat_recline_normal': '🪑',
  };

  return mapping[iconeCode] ?? '📦';
}

// ===============================================
// 🎨 UTILS - COULEURS PRODUITS
// ===============================================
class CouleurOption {
  final String nom;
  final Color couleur;

  const CouleurOption({
    required this.nom,
    required this.couleur,
  });
}

// ✅ SANS "const" - 100% fonctionnel
final List<CouleurOption> couleursProduits = [
  CouleurOption(nom: 'Blanc', couleur: Colors.white),
  CouleurOption(nom: 'Noir', couleur: Colors.black),
  CouleurOption(nom: 'Bleu', couleur: Colors.blue),
  CouleurOption(nom: 'Bleu Clair', couleur: Color(0xFF64B5F6)), // ✅ Hexa constant
  CouleurOption(nom: 'Rouge', couleur: Colors.red),
  CouleurOption(nom: 'Vert', couleur: Colors.green),
  CouleurOption(nom: 'Vert Clair', couleur: Color(0xFF81C784)), // ✅ Hexa constant
  CouleurOption(nom: 'Jaune', couleur: Color(0xFFFBC02D)), // ✅ Hexa constant
  CouleurOption(nom: 'Orange', couleur: Colors.orange),
  CouleurOption(nom: 'Cendre', couleur: Color(0xFFBDBDBD)), // ✅ Hexa constant
  CouleurOption(nom: 'Café', couleur: Color(0xFF6D4C41)), // ✅ Hexa constant
  CouleurOption(nom: 'Rose', couleur: Colors.pink),
  CouleurOption(nom: 'Violet', couleur: Colors.purple),
  CouleurOption(nom: 'Gris Foncé', couleur: Color(0xFF424242)), // ✅ Hexa constant
  CouleurOption(nom: 'Turquoise', couleur: Colors.teal),
  CouleurOption(nom: 'Beige', couleur: Color(0xFFBCAAA4)), // ✅ Hexa constant
  CouleurOption(nom: 'Menthe', couleur: Color(0xFF66BB6A)), // ✅ Hexa constant
  CouleurOption(nom: 'Bordeaux', couleur: Color(0xFF4A148C)), // ✅ Hexa constant
];
