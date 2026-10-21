import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../projects/project_dashboard.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = ref.watch(projectsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    final allTasks = <_TaskWithProject>[];
    for (final project in projects) {
      final tasks = ref.watch(tasksProvider(project.id));
      for (final task in tasks) {
        allTasks.add(_TaskWithProject(task: task, project: project));
      }
    }

    final todayTasks = allTasks.where((tp) {
      if (tp.task.status == TaskStatus.done) return false;
      if (tp.task.dueDate != null) {
        final due = DateTime(
          tp.task.dueDate!.year,
          tp.task.dueDate!.month,
          tp.task.dueDate!.day,
        );
        return due.isAtSameMomentAs(today);
      }
      return false;
    }).toList();

    final thisWeekTasks = allTasks.where((tp) {
      if (tp.task.status == TaskStatus.done) return false;
      if (tp.task.dueDate != null) {
        final due = DateTime(
          tp.task.dueDate!.year,
          tp.task.dueDate!.month,
          tp.task.dueDate!.day,
        );
        return due.isAfter(today) && due.isBefore(weekEnd);
      }
      return false;
    }).toList();

    final laterTasks = allTasks.where((tp) {
      if (tp.task.status == TaskStatus.done) return false;
      if (tp.task.dueDate == null) return true;
      final due = DateTime(
        tp.task.dueDate!.year,
        tp.task.dueDate!.month,
        tp.task.dueDate!.day,
      );
      return due.isAfter(weekEnd) || due.isAtSameMomentAs(weekEnd);
    }).toList();

    final doneToday = allTasks.where((tp) {
      if (tp.task.status != TaskStatus.done) return false;
      if (tp.task.dueDate != null) {
        final due = DateTime(
          tp.task.dueDate!.year,
          tp.task.dueDate!.month,
          tp.task.dueDate!.day,
        );
        return due.isAtSameMomentAs(today);
      }
      return false;
    }).length;

    return AppBackground(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: DefaultTabController(
            length: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aujourd\'hui',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1A1233),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE d MMMM', 'fr_FR').format(now),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsRow(todayTasks.length, doneToday, isDark),
                      const SizedBox(height: 16),
                      TabBar(
                        labelColor: NabuColors.violet,
                        unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
                        indicatorColor: NabuColors.violet,
                        tabs: const [
                          Tab(text: 'Aujourd\'hui'),
                          Tab(text: 'Cette semaine'),
                          Tab(text: 'Plus tard'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTaskList(context, ref, todayTasks, isDark, emptyMessage: 'Rien à faire aujourd\'hui !'),
                      _buildTaskList(context, ref, thisWeekTasks, isDark, emptyMessage: 'Aucune tâche cette semaine.'),
                      _buildTaskList(context, ref, laterTasks, isDark, emptyMessage: 'Tout est à jour.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(int todayTotal, int doneToday, bool isDark) {
    return Row(
      children: [
        _buildStatChip('$todayTotal tâche${todayTotal > 1 ? 's' : ''}', NabuColors.violet, isDark),
        const SizedBox(width: 8),
        _buildStatChip('$doneToday terminée${doneToday > 1 ? 's' : ''}', NabuColors.turquoise, isDark),
      ],
    );
  }

  Widget _buildStatChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<_TaskWithProject> items,
    bool isDark, {
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.check_circle_outline,
        message: emptyMessage,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final tp = items[index];
        return _buildTaskCard(context, ref, tp, isDark);
      },
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    WidgetRef ref,
    _TaskWithProject tp,
    bool isDark,
  ) {
    final task = tp.task;
    final project = tp.project;
    final isDone = task.status == TaskStatus.done;
    final categoryColor = CategoryColors.forCategory(project.category);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDashboardScreen(projectId: project.id),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _toggleTask(ref, tp),
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              child: Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 24,
                color: isDone
                    ? NabuColors.turquoise
                    : (isDark ? Colors.white38 : Colors.black26),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1233),
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM', 'fr_FR').format(task.dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PriorityBadge(priority: task.priority),
        ],
      ),
    );
  }

  void _toggleTask(WidgetRef ref, _TaskWithProject tp) {
    final newStatus =
        tp.task.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done;
    final updated = tp.task.copyWith(status: newStatus);
    ref.read(tasksProvider(tp.project.id).notifier).upsert(updated);

    ref.read(journalProvider(tp.project.id).notifier).upsert(
          JournalEntry(
            projectId: tp.project.id,
            content: newStatus == TaskStatus.done
                ? 'Tâche terminée : ${tp.task.title}'
                : 'Tâche réouverte : ${tp.task.title}',
            type: 'taskDone',
          ),
        );

    ref.read(projectsProvider.notifier).upsert(tp.project.copyWith());
  }
}

class _TaskWithProject {
  final Task task;
  final Project project;

  const _TaskWithProject({required this.task, required this.project});
}
