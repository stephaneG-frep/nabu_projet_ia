import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../projects/project_create_flow.dart';
import '../projects/projects_screen.dart';
import '../today/today_screen.dart';
import '../ai/ai_hub_screen.dart';
import '../ai/inspiration_screen.dart';
import '../projects/project_dashboard.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = ref.watch(projectsProvider);

    return AppBackground(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              title: Row(
                children: [
                  Text(
                    'NabuProjet IA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1233),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.auto_awesome, size: 16, color: NabuColors.cyan),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  _buildGreeting(isDark),
                  const SizedBox(height: 24),
                  _buildIdeaZone(context, isDark),
                  const SizedBox(height: 28),
                  _buildExplorerSection(context, ref, isDark),
                  const SizedBox(height: 28),
                  _buildProjectsSection(context, ref, projects, isDark),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour 👋',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A1233),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quel projet allons-nous faire avancer ?',
          style: TextStyle(
            fontSize: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildIdeaZone(BuildContext context, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProjectCreateFlowScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.25),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Décris ton idée...',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: '✨ Transformer mon idée en projet',
            icon: Icons.auto_awesome,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProjectCreateFlowScreen()),
            ),
            expanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildExplorerSection(BuildContext context, WidgetRef ref, bool isDark) {
    final items = [
      _QuickAction('Nouveau projet', Icons.add_box_outlined, NabuColors.violet,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectCreateFlowScreen()))),
      _QuickAction('Mes projets', Icons.folder_outlined, NabuColors.electricBlue,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen()))),
      _QuickAction('Aujourd\'hui', Icons.today_outlined, NabuColors.cyan,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodayScreen()))),
      _QuickAction('Assistant IA', Icons.auto_awesome, NabuColors.magenta,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIHubScreen()))),
      _QuickAction('Inspiration', Icons.emoji_objects_outlined, NabuColors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InspirationScreen()))),
      _QuickAction('Bilan', Icons.insights_outlined, NabuColors.turquoise,
          () => _showBilanPicker(context, ref)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Explorer',
          icon: Icons.explore_outlined,
          color: NabuColors.electricBlue,
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: items.map((item) {
            return GlassCard(
              padding: const EdgeInsets.all(14),
              onTap: item.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, size: 22, color: item.color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProjectsSection(
    BuildContext context,
    WidgetRef ref,
    List<Project> projects,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Continuer mes projets',
          icon: Icons.folder_open,
          color: NabuColors.violet,
        ),
        if (projects.isEmpty)
          EmptyState(
            icon: Icons.folder_open,
            message: 'Aucun projet pour l\'instant',
            subMessage: 'Transforme ta première idée en projet.',
            action: GradientButton(
              label: 'Créer un projet',
              icon: Icons.add,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProjectCreateFlowScreen()),
              ),
            ),
          )
        else
          ...projects.take(4).map((project) {
            final tasks = ref.watch(tasksProvider(project.id));
            final progress = computeProjectProgress(tasks);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GradientHeroCard(
                seed: project.colorSeed,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectDashboardScreen(projectId: project.id),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          project.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                project.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppProgressBar(
                      value: progress,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 6,
                    ),
                    if (project.nextAction.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Prochaine action : ${project.nextAction}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showBilanPicker(BuildContext context, WidgetRef ref) {
    final projects = ref.read(projectsProvider);
    if (projects.isEmpty) {
      showSnack(context, 'Aucun projet disponible', error: true);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1840) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choisir un projet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1233),
                  ),
                ),
                const SizedBox(height: 16),
                ...projects.map((p) {
                  return ListTile(
                    leading: Text(p.icon, style: const TextStyle(fontSize: 24)),
                    title: Text(p.name),
                    subtitle: Text(p.category),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDashboardScreen(projectId: p.id),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(this.label, this.icon, this.color, this.onTap);
}
