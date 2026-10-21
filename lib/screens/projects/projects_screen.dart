import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';
import 'project_create_flow.dart';
import 'project_dashboard.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  static const _filterLabels = ['Tous', 'En cours', 'En pause', 'Terminés', 'Archivés'];
  String _selectedFilter = 'Tous';

  ProjectStatus? _statusForFilter(String label) {
    switch (label) {
      case 'En cours':
        return ProjectStatus.active;
      case 'En pause':
        return ProjectStatus.paused;
      case 'Terminés':
        return ProjectStatus.completed;
      case 'Archivés':
        return ProjectStatus.archived;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = ref.watch(projectsProvider);
    final filter = _statusForFilter(_selectedFilter);
    final filtered = filter == null
        ? projects
        : projects.where((p) => p.status == filter).toList();

    return AppBackground(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mes projets',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1A1233),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${projects.length} projet${projects.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProjectCreateFlowScreen()),
                      ),
                      icon: const Icon(Icons.add, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: NabuColors.violet,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FilterChips(
                  labels: _filterLabels,
                  selected: _selectedFilter,
                  onSelected: (l) => setState(() => _selectedFilter = l),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.folder_open,
                        message: 'Aucun projet',
                        subMessage: 'Crée ton premier projet avec l\'IA.',
                        action: GradientButton(
                          label: 'Créer un projet',
                          icon: Icons.add,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProjectCreateFlowScreen()),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final project = filtered[index];
                          return _buildProjectCard(context, ref, project, isDark);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    WidgetRef ref,
    Project project,
    bool isDark,
  ) {
    final tasks = ref.watch(tasksProvider(project.id));
    final progress = computeProjectProgress(tasks);
    final updatedAt = _relativeDate(project.updatedAt);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDashboardScreen(projectId: project.id),
        ),
      ),
      onLongPress: () => _showProjectActions(context, ref, project, isDark),
      child: GradientHeroCard(
        seed: project.colorSeed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.icon,
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 10),
            Text(
              project.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              project.category,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const Spacer(),
            AppProgressBar(
              value: progress,
              color: Colors.white.withValues(alpha: 0.7),
              height: 5,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const Spacer(),
                Text(
                  'Mis à jour $updatedAt',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return DateFormat('d MMM', 'fr_FR').format(date);
  }

  void _showProjectActions(
    BuildContext context,
    WidgetRef ref,
    Project project,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                  project.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1233),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                _actionTile(
                  ctx,
                  Icons.edit_outlined,
                  'Renommer',
                  NabuColors.violet,
                  isDark,
                  () {
                    Navigator.pop(ctx);
                    _showRenameDialog(context, ref, project, isDark);
                  },
                ),
                _actionTile(
                  ctx,
                  Icons.flag_outlined,
                  'Changer de statut',
                  NabuColors.electricBlue,
                  isDark,
                  () {
                    Navigator.pop(ctx);
                    _showStatusPicker(context, ref, project, isDark);
                  },
                ),
                _actionTile(
                  ctx,
                  Icons.archive_outlined,
                  'Archiver',
                  NabuColors.orange,
                  isDark,
                  () {
                    Navigator.pop(ctx);
                    ref.read(projectsProvider.notifier).upsert(
                          project.copyWith(status: ProjectStatus.archived),
                        );
                    showSnack(context, 'Projet archivé');
                  },
                ),
                _actionTile(
                  ctx,
                  Icons.delete_outline,
                  'Supprimer',
                  NabuColors.red,
                  isDark,
                  () async {
                    Navigator.pop(ctx);
                    final confirmed = await confirmDialog(
                      context,
                      title: 'Supprimer le projet',
                      message:
                          'Voulez-vous vraiment supprimer "${project.name}" ? Cette action est irréversible.',
                    );
                    if (confirmed) {
                      ref.read(projectsProvider.notifier).remove(project.id);
                      if (context.mounted) {
                        showSnack(context, 'Projet supprimé');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionTile(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1A1233),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Project project,
    bool isDark,
  ) {
    final controller = TextEditingController(text: project.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renommer le projet'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nom du projet'),
          onSubmitted: (_) => _applyRename(ctx, ref, project, controller),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => _applyRename(ctx, ref, project, controller),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _applyRename(
    BuildContext ctx,
    WidgetRef ref,
    Project project,
    TextEditingController controller,
  ) {
    final name = controller.text.trim();
    if (name.isNotEmpty) {
      ref.read(projectsProvider.notifier).upsert(project.copyWith(name: name));
    }
    Navigator.pop(ctx);
  }

  void _showStatusPicker(
    BuildContext context,
    WidgetRef ref,
    Project project,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                  'Changer le statut',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1233),
                  ),
                ),
                const SizedBox(height: 12),
                ...ProjectStatus.values.map((status) {
                  final isActive = project.status == status;
                  return ListTile(
                    leading: Icon(status.icon, color: isActive ? NabuColors.violet : null),
                    title: Text(
                      status.label,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? NabuColors.violet
                            : (isDark ? Colors.white : const Color(0xFF1A1233)),
                      ),
                    ),
                    trailing: isActive
                        ? const Icon(Icons.check, color: NabuColors.violet)
                        : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(projectsProvider.notifier).upsert(
                            project.copyWith(status: status),
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
