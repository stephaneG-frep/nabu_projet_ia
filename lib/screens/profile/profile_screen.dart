import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../ai/ai_settings_screen.dart';
import '../help/help_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final projects = ref.watch(projectsProvider);
    final doneCount = ref
        .watch(projectsProvider)
        .fold<int>(0, (sum, p) {
      final tasks = ref.read(tasksProvider(p.id));
      return sum + tasks.where((t) => t.isDone).length;
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        isDark: isDark,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('👤 Profil',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      GradientHeroCard(
                        seed: 0,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settings.userName.isEmpty
                                        ? 'Amateur de projets'
                                        : settings.userName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    '${projects.length} projet(s) actif(s)',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: Colors.white),
                              onPressed: () => _editName(context, ref),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SectionTitle(
                          title: 'Statistiques',
                          icon: Icons.insights_outlined,
                          color: NabuColors.cyan),
                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              child: Column(
                                children: [
                                  Text('${projects.length}',
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: NabuColors.violet)),
                                  Text('Projets',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassCard(
                              child: Column(
                                children: [
                                  Text('$doneCount',
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: NabuColors.green)),
                                  Text('Tâches faites',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassCard(
                              child: Column(
                                children: [
                                  Text(
                                      projects
                                          .where((p) =>
                                              p.status.name == 'completed')
                                          .length
                                          .toString(),
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: NabuColors.turquoise)),
                                  Text('Terminés',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const SectionTitle(
                          title: 'Personnalisation',
                          icon: Icons.palette_outlined,
                          color: NabuColors.magenta),
                      GlassCard(
                        child: Row(
                          children: [
                            Icon(
                              isDark
                                  ? Icons.dark_mode_outlined
                                  : Icons.light_mode_outlined,
                              color: NabuColors.magenta,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('Thème sombre',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            Switch(
                              value: settings.darkMode,
                              activeThumbColor: NabuColors.violet,
                              onChanged: (v) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .setDarkMode(v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SectionTitle(
                          title: 'NabuProjet IA',
                          icon: Icons.auto_awesome,
                          color: NabuColors.violet),
                      GlassCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AISettingsScreen()),
                        ),
                        child: const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.cloud_outlined,
                              color: NabuColors.violet),
                          title: Text('Fournisseur IA',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              'OpenAI, Gemini, Mistral, Claude, Ollama'),
                          trailing: Icon(Icons.chevron_right),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HelpScreen()),
                        ),
                        child: const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.menu_book_outlined,
                              color: NabuColors.cyan),
                          title: Text('📖 Mode d’emploi',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              'Tout savoir sur NabuProjet IA'),
                          trailing: Icon(Icons.chevron_right),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.shield_outlined,
                                  color: NabuColors.green),
                              title: Text('Sauvegarde locale',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  'Tes projets sont enregistrés sur cet appareil'),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                  '🔄 Les projets, tâches, conversations, notes et préférences ne disparaissent jamais quand tu fermes l’application.'),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      GlassCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.info_outline,
                              color: NabuColors.orange),
                          title: const Text('À propos',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: const Text(
                              'NabuProjet IA · version 1.0.0'),
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('NabuProjet IA'),
                              content: const Text(
                                  'Un chef de projet personnel propulsé par l’IA.\n\nIDÉE → DISCUSSION → PLAN → ACTION → SUIVI → ADAPTATION → RÉUSSITE\n\nVersion 1.0.0'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Fermer')),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editName(BuildContext context, WidgetRef ref) {
    final current =
        ref.read(settingsProvider).userName.isEmpty ? '' : ref.read(settingsProvider).userName;
    final ctrl = TextEditingController(text: current);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F1840) : Colors.white,
        title: const Text('Ton nom'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Ex : Karim, Marie...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () {
                ref
                    .read(settingsProvider.notifier)
                    .setUserName(ctrl.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text('Enregistrer')),
        ],
      ),
    );
  }
}