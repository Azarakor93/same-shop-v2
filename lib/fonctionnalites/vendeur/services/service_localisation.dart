// ===============================================
// 📍 SERVICE LOCALISATION
// ===============================================
// Gère la géolocalisation de l'utilisateur
// pour positionner les boutiques sur la carte

import 'package:geolocator/geolocator.dart';

class ServiceLocalisation {
  // ===============================================
  // 🔧 SINGLETON PATTERN
  // ===============================================
  static final ServiceLocalisation _instance = ServiceLocalisation._internal();
  factory ServiceLocalisation() => _instance;
  ServiceLocalisation._internal();

  // ===============================================
  // 📍 RÉCUPÉRER LA POSITION ACTUELLE
  // ===============================================
  /// Récupère la position GPS actuelle de l'utilisateur
  ///
  /// Throws Exception si:
  /// - Le service de localisation est désactivé
  /// - La permission est refusée
  Future<Position> positionActuelle() async {
    // ===============================================
    // 1️⃣ VÉRIFIER SI LE SERVICE EST ACTIVÉ
    // ===============================================
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        '📍 Service de localisation désactivé.\n'
        'Veuillez l\'activer dans les paramètres.',
      );
    }

    // ===============================================
    // 2️⃣ VÉRIFIER / DEMANDER LA PERMISSION
    // ===============================================
    LocationPermission permission = await Geolocator.checkPermission();

    // Permission refusée → Demander
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception(
          '❌ Permission de localisation refusée.\n'
          'Veuillez autoriser l\'accès dans les paramètres.',
        );
      }
    }

    // Permission refusée définitivement
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        '🚫 Permission de localisation refusée définitivement.\n'
        'Veuillez l\'activer manuellement dans les paramètres de l\'application.',
      );
    }

    // ===============================================
    // 3️⃣ PARAMÈTRES DE LOCALISATION
    // ===============================================
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // mètres avant nouvelle position
    );

    // ===============================================
    // 4️⃣ RÉCUPÉRER LA POSITION
    // ===============================================
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } catch (e) {
      throw Exception(
        '⚠️ Impossible de récupérer la position.\n'
        'Vérifiez votre connexion GPS et réessayez.',
      );
    }
  }

  // ===============================================
  // 📏 CALCULER LA DISTANCE ENTRE DEUX POINTS
  // ===============================================
  /// Calcule la distance en mètres entre deux positions GPS
  double calculerDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // ===============================================
  // 📏 FORMATER LA DISTANCE
  // ===============================================
  /// Formate une distance en mètres en texte lisible
  ///
  /// Exemples:
  /// - 500m → "500 m"
  /// - 1200m → "1.2 km"
  /// - 5400m → "5.4 km"
  String formaterDistance(double distanceEnMetres) {
    if (distanceEnMetres < 1000) {
      return '${distanceEnMetres.round()} m';
    } else {
      final km = distanceEnMetres / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  // ===============================================
  // 🗺️ VÉRIFIER SI UNE POSITION EST DANS UN RAYON
  // ===============================================
  /// Vérifie si une position est dans un rayon donné
  bool estDansRayon({
    required double latCentre,
    required double lonCentre,
    required double latPoint,
    required double lonPoint,
    required double rayonEnMetres,
  }) {
    final distance = calculerDistance(
      lat1: latCentre,
      lon1: lonCentre,
      lat2: latPoint,
      lon2: lonPoint,
    );

    return distance <= rayonEnMetres;
  }

  // ===============================================
  // 📱 OUVRIR LES PARAMÈTRES DE LOCALISATION
  // ===============================================
  /// Ouvre les paramètres de l'application
  Future<bool> ouvrirParametres() async {
    return await Geolocator.openLocationSettings();
  }

  // ===============================================
  // ✅ VÉRIFIER SI LA PERMISSION EST ACCORDÉE
  // ===============================================
  Future<bool> permissionAccordee() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
