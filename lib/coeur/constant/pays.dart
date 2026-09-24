class Pays {
  final String nom;
  final String code;
  final String flag;
  final int longueurNumero; // ✅ NOUVEAU
  final bool prioritaire; // Afrique en priorité

  const Pays({
    required this.nom,
    required this.code,
    required this.flag,
    required this.longueurNumero,
    this.prioritaire = false,
  });
}

const List<Pays> listePays = [
  Pays(
    nom: 'Togo',
    code: '+228',
    flag: '🇹🇬',
    longueurNumero: 8,
    prioritaire: true,
  ),
  Pays(
    nom: 'Bénin',
    code: '+229',
    flag: '🇧🇯',
    longueurNumero: 8,
    prioritaire: true,
  ),
  Pays(
    nom: 'Côte d’Ivoire',
    code: '+225',
    flag: '🇨🇮',
    longueurNumero: 10,
    prioritaire: true,
  ),
  Pays(
    nom: 'Sénégal',
    code: '+221',
    flag: '🇸🇳',
    longueurNumero: 9,
    prioritaire: true,
  ),
];

List<Pays> paysTries() {
  final priorite = listePays.where((p) => p.prioritaire).toList()
    ..sort((a, b) => a.nom.compareTo(b.nom));

  final autres = listePays.where((p) => !p.prioritaire).toList()
    ..sort((a, b) => a.nom.compareTo(b.nom));

  return [...priorite, ...autres];
}
