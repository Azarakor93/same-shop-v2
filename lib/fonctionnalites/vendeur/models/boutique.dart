// ===============================================
// 🏪 MODÈLE BOUTIQUE
// ===============================================
// Représente une boutique créée par un vendeur
// avec toutes ses informations et métadonnées

class Boutique {
  final String id;
  final String nomBoutique;
  final String? description;
  final String telephone;
  final String pays;
  final String ville;
  final String? quartier;
  final String? logoUrl;
  final double latitude;
  final double longitude;
  final TypeAbonnement typeAbonnement;
  final bool estVerifie;
  final bool estSuspendu;
  final DateTime? dateExpirationAbonnement;
  final DateTime createdAt;

  const Boutique({
    required this.id,
    required this.nomBoutique,
    this.description,
    required this.telephone,
    required this.pays,
    required this.ville,
    this.quartier,
    this.logoUrl,
    required this.latitude,
    required this.longitude,
    this.typeAbonnement = TypeAbonnement.gratuit,
    this.estVerifie = false,
    this.estSuspendu = false,
    this.dateExpirationAbonnement,
    required this.createdAt,
  });

  // ===============================================
  // 📥 DÉSÉRIALISATION (Supabase → Dart)
  // ===============================================
  factory Boutique.fromMap(Map<String, dynamic> map) {
    return Boutique(
      id: map['id'] as String,
      nomBoutique: map['nom_boutique'] as String,
      description: map['description'] as String?,
      telephone: map['telephone'] as String,
      pays: map['pays'] as String,
      ville: map['ville'] as String,
      quartier: map['quartier'] as String?,
      logoUrl: map['logo_url'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      typeAbonnement: _parseTypeAbonnement(map['type_abonnement']),
      estVerifie: map['est_verifie'] as bool? ?? false,
      estSuspendu: map['est_suspendu'] as bool? ?? false,
      dateExpirationAbonnement: map['date_expiration_abonnement'] != null ? DateTime.parse(map['date_expiration_abonnement'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // ===============================================
  // 📤 SÉRIALISATION (Dart → Supabase)
  // ===============================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom_boutique': nomBoutique,
      'description': description,
      'telephone': telephone,
      'pays': pays,
      'ville': ville,
      'quartier': quartier,
      'logo_url': logoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'type_abonnement': typeAbonnement.value,
      'est_verifie': estVerifie,
      'est_suspendu': estSuspendu,
      'date_expiration_abonnement': dateExpirationAbonnement?.toIso8601String(),
    };
  }

  // ===============================================
  // 🔄 COPY WITH (pour modifications)
  // ===============================================
  Boutique copyWith({
    String? id,
    String? nomBoutique,
    String? description,
    String? telephone,
    String? pays,
    String? ville,
    String? quartier,
    String? logoUrl,
    double? latitude,
    double? longitude,
    TypeAbonnement? typeAbonnement,
    bool? estVerifie,
    bool? estSuspendu,
    DateTime? dateExpirationAbonnement,
    DateTime? createdAt,
  }) {
    return Boutique(
      id: id ?? this.id,
      nomBoutique: nomBoutique ?? this.nomBoutique,
      description: description ?? this.description,
      telephone: telephone ?? this.telephone,
      pays: pays ?? this.pays,
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      logoUrl: logoUrl ?? this.logoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      typeAbonnement: typeAbonnement ?? this.typeAbonnement,
      estVerifie: estVerifie ?? this.estVerifie,
      estSuspendu: estSuspendu ?? this.estSuspendu,
      dateExpirationAbonnement: dateExpirationAbonnement ?? this.dateExpirationAbonnement,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ===============================================
  // 🔍 HELPER - Parse le type d'abonnement
  // ===============================================
  static TypeAbonnement _parseTypeAbonnement(dynamic value) {
    if (value == null) return TypeAbonnement.gratuit;
    if (value == 'premium') return TypeAbonnement.premium;
    return TypeAbonnement.gratuit;
  }

  // ===============================================
  // ✅ VÉRIFICATIONS UTILES
  // ===============================================
  bool get estPremium => typeAbonnement == TypeAbonnement.premium;
  bool get estActif => !estSuspendu;
  bool get peutCreerProduits => estActif && !estSuspendu;

  bool get abonnementExpire {
    if (!estPremium) return false;
    if (dateExpirationAbonnement == null) return false;
    return DateTime.now().isAfter(dateExpirationAbonnement!);
  }

  String get adresseComplete {
    final parts = [quartier, ville, pays].where((e) => e != null && e.isNotEmpty);
    return parts.join(', ');
  }
}

// ===============================================
// 🎯 ENUM TYPE ABONNEMENT
// ===============================================
enum TypeAbonnement {
  gratuit('gratuit'),
  premium('premium'), // ← Virgule ici (pas point-virgule)
  entreprise('entreprise'); // ← Point-virgule seulement à la fin

  final String value;
  const TypeAbonnement(this.value);

  String get label {
    switch (this) {
      case TypeAbonnement.gratuit:
        return 'Gratuit';
      case TypeAbonnement.premium:
        return 'Premium';
      case TypeAbonnement.entreprise:
        return 'Entreprise';
    }
  }
}
