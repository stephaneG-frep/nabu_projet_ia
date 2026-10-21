part of '../section_screens.dart';

class ProjectKanbanScreen extends ConsumerWidget {
  final String projectId;
  const ProjectKanbanScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider(projectId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cols = [
      TaskStatus.todo,
      TaskStatus.inProgress,
      TaskStatus.blocked,
      TaskStatus.done,
    ];

    final colColors = {
      TaskStatus.todo: NabuColors.violet,
      TaskStatus.inProgress: NabuColors.cyan,
      TaskStatus.blocked: const Color(0xFFFF5252),
      TaskStatus.done: NabuColors.green,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Kanban'),
      ),
      body: AppBackground(
        isDark: isDark,
        child: RawScrollbar(
          thumbVisibility: false,
          controller: ScrollController(),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            children: cols.map((status) {
              final colTasks = tasks
                  .where((t) => t.status == status)
                  .toList()
                ..sort((a, b) => b.priority.weight.compareTo(a.priority.weight));
              final color = colColors[status]!;
              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(status.icon, color: color, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            status.label,
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text('${colTasks.length}',
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: DragTarget<Task>(
                        onWillAcceptWithDetails: (_) => true,
                        onAcceptWithDetails: (details) {
                          final t = details.data;
                          ref
                              .read(tasksProvider(projectId).notifier)
                              .upsert(t.copyWith(status: status));
                          if (status == TaskStatus.done && !t.isDone) {
                            ref
                                .read(journalProvider(projectId).notifier)
                                .upsert(JournalEntry(
                                  projectId: projectId,
                                  content: 'Tâche terminée : ${t.title}.',
                                  type: 'taskDone',
                                ));
                          }
                        },
                        builder: (ctx, candidates, rejects) => Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : Colors.black.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding:
                              const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: colTasks.isEmpty
                              ? Center(
                                  child: Text(
                                    'Glisse une tâche ici',
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black26),
                                  ),
                                )
                              : ListView(
                                  children: colTasks.map((t) {
                                    return Draggable<Task>(
                                      data: t,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: GlassCard(
                                            padding: const EdgeInsets.all(12),
                                            child: Text(t.title,
                                                maxLines: 2)),
                                      ),
                                      childWhenDragging: Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.04)
                                              : Colors.black.withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: GlassCard(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14),
                                            ),
                                            const SizedBox(height: 6),
                                            PriorityBadge(priority: t.priority),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
