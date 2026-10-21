import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../projects/project_create_flow.dart';
import '../projects/project_chat.dart';
import '../help/help_screen.dart';
import 'inspiration_screen.dart';
import 'ai_settings_screen.dart';

class AIHubScreen extends ConsumerWidget {
  const AIHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        isDark: isDark,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✨ Assistant IA',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        'Ton chef de projet personnel, prêt à t’aider.',
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.5)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    GradientHeroCard(
                      seed: 4,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProjectCreateFlowScreen()),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              color: Colors.white, size: 32),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Une idée ?',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('Transforme-la en projet structuré.',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const InspirationScreen()),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.emoji_objects_outlined,
                              color: NabuColors.orange, size: 26),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Inspiration',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                Text('Je manque d’idées… surprends-moi !',
                                    style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AISettingsScreen()),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.settings_outlined,
                              color: NabuColors.violet, size: 26),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fournisseur IA',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                Text('Configurer la clé API et le modèle',
                                    style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HelpScreen()),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.menu_book_outlined,
                              color: NabuColors.cyan, size: 26),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mode d’emploi',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                Text('Apprendre à utiliser NabuProjet IA',
                                    style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle(
                        title: 'Discuter avec un chef de projet',
                        icon: Icons.forum_outlined,
                        color: NabuColors.magenta),
                    if (projects.isEmpty)
                      GlassCard(
                        child: Text(
                          'Crée d’abord un projet pour discuter avec son chef de projet IA.',
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.black45),
                        ),
                      )
                    else
                      ...projects
                          .where((p) => p.status == ProjectStatus.active)
                          .take(4)
                          .map((p) => GlassCard(
                                margin: const EdgeInsets.only(bottom: 10),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ProjectChatScreen(
                                          projectId: p.id)),
                                ),
                                child: Row(
                                  children: [
                                    Text(p.icon, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w700)),
                                          Text(
                                            'Discuter avec ${p.name}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.black45),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              )),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}