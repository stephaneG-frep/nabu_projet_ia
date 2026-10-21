part of '../section_screens.dart';

class _ObjectivesSection extends ConsumerWidget {
  final String projectId;
  const _ObjectivesSection({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final objectives = ref.watch(objectivesProvider(projectId));
    final mains = objectives.where((o) => o.isMain).toList();
    final seconds = objectives.where((o) => !o.isMain).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
            title: 'Objectif principal',
            icon: Icons.flag_outlined,
            color: NabuColors.violet),
        if (mains.isEmpty)
          GlassCard(child: Text(mains.isEmpty ? 'Objectif principal : à définir.' : ''))
        else
          ...mains.map((o) => _ObjectiveCard(objective: o)),
        const SizedBox(height: 20),
        const SectionTitle(
            title: 'Objectifs secondaires',
            icon: Icons.flag,
            color: NabuColors.violet),
        if (seconds.isEmpty)
          GlassCard(
              child: Text('Aucun objectif secondaire.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
        else
          ...seconds.map((o) => _ObjectiveCard(objective: o)),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Ajouter un objectif',
          icon: Icons.add,
          expanded: true,
          onPressed: () => _addObjective(context, ref),
        ),
      ],
    );
  }

  Future<void> _addObjective(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1F1840) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouvel objectif',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'Ex. : Terminer la maquette'),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Ajouter',
                icon: Icons.check,
                expanded: true,
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              ),
            ],
          ),
        ),
      ),
    );
    if (title != null && title.isNotEmpty) {
      ref.read(objectivesProvider(projectId).notifier).upsert(Objective(
            projectId: projectId,
            title: title,
            isMain: ref.read(objectivesProvider(projectId)).isEmpty,
          ));
    }
  }
}

class _ObjectiveCard extends ConsumerWidget {
  final Objective objective;
  const _ObjectiveCard({required this.objective});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = objective.status == TaskStatus.done;
    final color = objective.isMain ? NabuColors.violet : NabuColors.deepViolet;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () {
        final newStatus = done
            ? TaskStatus.todo
            : objective.status == TaskStatus.inProgress
                ? TaskStatus.done
                : TaskStatus.inProgress;
        ref
            .read(objectivesProvider(objective.projectId).notifier)
            .upsert(objective.copyWith(status: newStatus));
      },
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            color: done ? NabuColors.green : color,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  objective.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: isDark ? Colors.white : const Color(0xFF1A1233),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadge(
                      label: objective.status.label,
                      color: done
                          ? NabuColors.green
                          : objective.status == TaskStatus.inProgress
                              ? NabuColors.cyan
                              : color,
                    ),
                    if (objective.dueDate != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd/MM')
                            .format(objective.dueDate!),
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : Colors.black45),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') {
                ref
                    .read(objectivesProvider(objective.projectId).notifier)
                    .remove(objective.id);
              }
              if (v == 'priority') {
                ref
                    .read(objectivesProvider(objective.projectId).notifier)
                    .upsert(objective.copyWith(
                        priority: objective.priority == Priority.high
                            ? Priority.normal
                            : Priority.high));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'priority',
                  child: Text(objective.priority == Priority.high
                      ? 'Priorité normale'
                      : 'Priorité haute')),
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }
}
