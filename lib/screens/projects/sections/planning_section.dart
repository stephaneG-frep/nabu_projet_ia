part of '../section_screens.dart';

class _PlanningSection extends ConsumerWidget {
  final String projectId;
  const _PlanningSection({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasks = ref.watch(tasksProvider(projectId));
    final project = ref.read(projectsProvider).firstWhere(
          (p) => p.id == projectId,
          orElse: () => Project(name: ''),
        );

    final today = DateTime.now();
    final todayTasks = tasks
        .where((t) => t.dueDate != null &&
            t.dueDate!.day == today.day &&
            t.dueDate!.month == today.month &&
            t.dueDate!.year == today.year)
        .toList();
    final weekTasks = tasks
        .where((t) =>
            t.dueDate != null &&
            !(t.dueDate!.day == today.day &&
                t.dueDate!.month == today.month &&
                t.dueDate!.year == today.year) &&
            t.dueDate!.isBefore(today.add(const Duration(days: 7))) &&
            t.dueDate!.isAfter(today))
        .toList();
    final laterTasks =
        tasks.where((t) => t.dueDate == null ||
            (t.dueDate!.isAfter(today.add(const Duration(days: 7))))).toList();

    final phases = [
      ('IDÉE', Icons.lightbulb_outline, true),
      ('PRÉPARATION', Icons.map_outlined,
          tasks.any((t) => t.status != TaskStatus.todo &&
              t.status != TaskStatus.done)),
      ('PROTOTYPE', Icons.construction, false),
      ('TEST', Icons.science_outlined, false),
      ('AMÉLIORATION', Icons.tune, false),
      ('FINALISATION', Icons.flag_outlined, false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
            title: 'Aujourd’hui',
            icon: Icons.today,
            color: NabuColors.cyan),
        if (todayTasks.isEmpty)
          GlassCard(
              child: Text('Rien de prévu aujourd’hui. 🎉',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
        else
          ...todayTasks.map((t) => _TaskCard(task: t)),
        const SizedBox(height: 16),
        const SectionTitle(
            title: 'Cette semaine',
            icon: Icons.calendar_view_week,
            color: NabuColors.electricBlue),
        if (weekTasks.isEmpty)
          GlassCard(
              child: Text('Aucune échéance cette semaine.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
        else
          ...weekTasks.map((t) => _TaskCard(task: t)),
        const SizedBox(height: 16),
        const SectionTitle(
            title: 'Plus tard',
            icon: Icons.event_outlined,
            color: NabuColors.violet),
        if (laterTasks.isEmpty)
          GlassCard(
              child: Text('Aucune tâche planifiée plus tard.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
        else
          ...laterTasks.map((t) => _TaskCard(task: t)),
        const SizedBox(height: 20),
        const SectionTitle(
            title: 'Timeline du projet',
            icon: Icons.vertical_align_bottom,
            color: NabuColors.magenta),
        GlassCard(
          child: Column(
            children: [
              for (var i = 0; i < phases.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == 0
                                ? NabuColors.magenta
                                : isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                            border: i == 0
                                ? null
                                : Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12),
                          ),
                          child: Icon(phases[i].$2,
                              size: 18,
                              color: i == 0
                                  ? Colors.white
                                  : isDark
                                      ? Colors.white54
                                      : Colors.black45),
                        ),
                        if (i < phases.length - 1)
                          Container(width: 2, height: 28, color: NabuColors.violet.withValues(alpha: 0.3)),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        phases[i].$1,
                        style: TextStyle(
                          fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 14,
                          color: i == 0
                              ? NabuColors.magenta
                              : isDark
                                  ? Colors.white70
                                  : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: NabuColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Position actuelle : ${phases[0].$1}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: NabuColors.cyan,
                        fontSize: 13)),
              ),
              const SizedBox(height: 10),
              Text(
                'Durée estimée du projet : ${project.estimatedDays} jours',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
