import 'package:flutter/foundation.dart';

@immutable
class PanierLigne {
  final String produitId;
  final String vendeurId;
  final String nom;
  final int prixUnitaire;
  final String? imageUrl;
  final int quantite;
  final String? taille;
  final String? couleur;

  const PanierLigne({
    required this.produitId,
    required this.vendeurId,
    required this.nom,
    required this.prixUnitaire,
    required this.imageUrl,
    required this.quantite,
    required this.taille,
    required this.couleur,
  });

  String get cle => [
        produitId,
        taille ?? '',
        couleur ?? '',
      ].join('|');

  int get total => prixUnitaire * quantite;

  PanierLigne copyWith({
    String? produitId,
    String? vendeurId,
    String? nom,
    int? prixUnitaire,
    String? imageUrl,
    int? quantite,
    String? taille,
    String? couleur,
  }) {
    return PanierLigne(
      produitId: produitId ?? this.produitId,
      vendeurId: vendeurId ?? this.vendeurId,
      nom: nom ?? this.nom,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      imageUrl: imageUrl ?? this.imageUrl,
      quantite: quantite ?? this.quantite,
      taille: taille ?? this.taille,
      couleur: couleur ?? this.couleur,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'produit_id': produitId,
      'vendeur_id': vendeurId,
      'nom': nom,
      'prix_unitaire': prixUnitaire,
      'image_url': imageUrl,
      'quantite': quantite,
      'taille': taille,
      'couleur': couleur,
    };
  }

  factory PanierLigne.fromJson(Map<String, dynamic> json) {
    return PanierLigne(
      produitId: json['produit_id'] as String,
      vendeurId: json['vendeur_id'] as String,
      nom: json['nom'] as String,
      prixUnitaire: (json['prix_unitaire'] as num).toInt(),
      imageUrl: json['image_url'] as String?,
      quantite: (json['quantite'] as num?)?.toInt() ?? 1,
      taille: json['taille'] as String?,
      couleur: json['couleur'] as String?,
    );
  }
}

