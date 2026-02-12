import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../coeur/services/preferences_service.dart';
import '../../coeur/services/supabase_preferences_service.dart';

class EcranProfil extends StatefulWidget {
  const EcranProfil({super.key});

  @override
  State<EcranProfil> createState() => _EcranProfilState();
}

class _EcranProfilState extends State<EcranProfil> {
  final SupabasePreferencesService _supabasePrefs = SupabasePreferencesService();

  bool _chargement = true;
  bool _sauvegardeEnCours = false;

  Locale _langue = const Locale('fr');
  ThemeMode _themeMode = ThemeMode.system;

  User? get _user => Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _chargerPreferences();
  }

  Future<void> _chargerPreferences() async {
    final localeLocal = await PreferencesService.chargerLangue();
    final themeLocal = await PreferencesService.chargerTheme();

    Locale langue = localeLocal;
    ThemeMode theme = themeLocal;

    final prefsCloud = await _supabasePrefs.chargerPreferences();
    if (prefsCloud != null) {
      langue = Locale(prefsCloud['language'] ?? 'fr');
      theme = _themeDepuisNom(prefsCloud['theme'] ?? 'system');
    }

    if (!mounted) return;
    setState(() {
      _langue = langue;
      _themeMode = theme;
      _chargement = false;
    });
  }

  ThemeMode _themeDepuisNom(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _sauvegarderPreferences() async {
    setState(() => _sauvegardeEnCours = true);

    try {
      await PreferencesService.sauvegarderLangue(_langue);
      await PreferencesService.sauvegarderTheme(_themeMode);
      await _supabasePrefs.sauvegarderPreferences(
        locale: _langue,
        themeMode: _themeMode,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préférences sauvegardées. Elles seront appliquées au prochain démarrage.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de sauvegarder les préférences.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sauvegardeEnCours = false);
      }
    }
  }

  Future<void> _deconnexion() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = _user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(user?.email ?? 'Utilisateur connecté'),
            subtitle: Text('ID: ${user?.id ?? '-'}'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Préférences',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Locale>(
                  value: _langue,
                  decoration: const InputDecoration(
                    labelText: 'Langue',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
                    DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _langue = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ThemeMode>(
                  value: _themeMode,
                  decoration: const InputDecoration(
                    labelText: 'Thème',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('Système')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Clair')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Sombre')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _themeMode = value);
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _sauvegardeEnCours ? null : _sauvegarderPreferences,
                  icon: _sauvegardeEnCours
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Sauvegarder'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                subtitle: const Text('Configuration détaillée à venir'),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Sécurité'),
                subtitle: const Text('Sessions et mot de passe (prochaine étape)'),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Historique paiements'),
                subtitle: const Text('Abonnements, boosts, packs'),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _deconnexion,
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
        ),
      ],
    );
  }
}
