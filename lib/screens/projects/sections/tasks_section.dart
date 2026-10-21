part of '../section_screens.dart';

class _TasksSection extends ConsumerWidget {
  final String projectId;
  final TabController tabC;
  const _TasksSection({
    required this.projectId,
    required this.tabC,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider(projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GradientButton(
                label: 'Nouvelle tâche',
                icon: Icons.add_task,
                expanded: true,
                onPressed: () => _addTask(context, ref),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              icon: const Icon(Icons.view_kanban_outlined),
              tooltip: 'Vue Kanban',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        ProjectKanbanScreen(projectId: projectId)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TabBar(
          controller: tabC,
          tabs: [
            Tab(text: 'Liste (${tasks.length})'),
            Tab(text: 'Kanban'),
            Tab(text: 'Statut'),
          ],
        ),
        const SizedBox(height: 8),
        if (tabC.index == 0 || tabC.index == 2)
          ..._listTab(tasks, TaskStatus.todo, tabC.index)
        else
          _miniKanban(tasks, context),
      ],
    );
  }

  List<Widget> _listTab(List<Task> tasks, TaskStatus current, int mode) {
    List<Task> shown;
    if (mode == 0) {
      shown = tasks;
    } else {
      shown = tasks.where((t) => t.status == current).toList();
    }
    if (shown.isEmpty) {
      return [
        GlassCard(
          child: Text(mode == 0
              ? 'Aucune tâche pour le moment. Ajoute ta première tâche !'
              : 'Aucune tâche dans « ${current.label} ».'),
        ),
      ];
    }
    return shown.map((t) => _TaskCard(task: t)).toList();
  }

  Widget _miniKanban(List<Task> tasks, BuildContext context) {
    final cols = {
      TaskStatus.todo: tasks.where((t) => t.status == TaskStatus.todo).length,
      TaskStatus.inProgress:
          tasks.where((t) => t.status == TaskStatus.inProgress).length,
      TaskStatus.blocked:
          tasks.where((t) => t.status == TaskStatus.blocked).length,
      TaskStatus.done: tasks.where((t) => t.status == TaskStatus.done).length,
    };
    return GlassCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: cols.entries
                .map((e) => Column(
                      children: [
                        Icon(e.key.icon,
                            color: _colColor(e.key),
                            size: 24),
                        const SizedBox(height: 4),
                        Text('${e.value}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        Text(e.key.label,
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProjectKanbanScreen(projectId: projectId)),
            ),
            icon: const Icon(Icons.open_in_full),
            label: const Text('Ouvrir le Kanban complet'),
          ),
        ],
      ),
    );
  }

  Color _colColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return NabuColors.violet;
      case TaskStatus.inProgress:
        return NabuColors.cyan;
      case TaskStatus.blocked:
        return const Color(0xFFFF5252);
      case TaskStatus.done:
        return NabuColors.green;
    }
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final minutesCtrl = TextEditingController(text: '60');
    DateTime? dueDate;
    var priority = Priority.normal;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Dialog(
          backgroundColor: isDark ? const Color(0xFF1F1840) : Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouvelle tâche',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration:
                      const InputDecoration(labelText: 'Titre de la tâche'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Description (optionnelle)'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minutesCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Durée (min)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null) setSheet(() => dueDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              labelText: 'Échéance (option)'),
                          child: Text(dueDate == null
                              ? 'Aucune'
                              : DateFormat('dd/MM/yyyy').format(dueDate!)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Priority>(
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priorité'),
                  items: Priority.values
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text(p.label)))
                      .toList(),
                  onChanged: (v) =>
                      setSheet(() => priority = v ?? Priority.normal),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: 'Ajouter la tâche',
                  icon: Icons.check,
                  expanded: true,
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) {
                      showSnack(context, 'Donne un titre à la tâche.',
                          error: true);
                      return;
                    }
                    ref
                        .read(tasksProvider(projectId).notifier)
                        .upsert(Task(
                          projectId: projectId,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          priority: priority,
                          estimatedMinutes:
                              int.tryParse(minutesCtrl.text) ?? 60,
                          dueDate: dueDate,
                          order: ref.read(tasksProvider(projectId)).length,
                        ));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final Task task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = task.isDone;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  ref
                      .read(tasksProvider(task.projectId).notifier)
                      .upsert(task.copyWith(
                          status: done
                              ? TaskStatus.todo
                              : TaskStatus.done));
                  if (!done) {
                    ref
                        .read(journalProvider(task.projectId).notifier)
                        .upsert(JournalEntry(
                            projectId: task.projectId,
                            content: 'Tâche terminée : ${task.title}.',
                            type: 'taskDone'));
                  }
                },
                child: Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done ? NabuColors.green : NabuColors.violet,
                  size: 26,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF1A1233),
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : Colors.black45),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  final notifier = ref.read(tasksProvider(task.projectId).notifier);
                  switch (v) {
                    case 'start':
                      notifier.upsert(
                          task.copyWith(status: TaskStatus.inProgress));
                    case 'block':
                      notifier.upsert(task.copyWith(status: TaskStatus.blocked));
                    case 'edit':
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          final c = TextEditingController(text: task.title);
                          final d = TextEditingController(
                              text: task.description);
                          return AlertDialog(
                            title: const Text('Modifier la tâche'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                    controller: c,
                                    decoration: const InputDecoration(
                                        labelText: 'Titre')),
                                TextField(
                                    controller: d,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                        labelText: 'Description')),
                              ],
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Annuler')),
                              FilledButton(
                                  onPressed: () {
                                    notifier.upsert(task.copyWith(
                                        title: c.text.trim(),
                                        description: d.text.trim()));
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Sauvegarder')),
                            ],
                          );
                        },
                      );
                    case 'delete':
                      confirmDialog(context,
                              title: 'Supprimer la tâche ?',
                              message:
                                  '« ${task.title} » sera définitivement supprimée. ${task.subtasks.isNotEmpty ? "Ses ${task.subtasks.length} sous-tâches aussi." : ""}')
                          .then((ok) {
                        if (ok == true) notifier.remove(task.id);
                      });
                  }
                },
                itemBuilder: (_) => [
                  if (task.status != TaskStatus.inProgress)
                    const PopupMenuItem(value: 'start', child: Text('▶️ Démarrer')),
                  if (task.status != TaskStatus.blocked)
                    const PopupMenuItem(value: 'block', child: Text('⛔ Bloquée')),
                  const PopupMenuItem(value: 'edit', child: Text('✏️ Modifier')),
                  const PopupMenuItem(value: 'delete', child: Text('🗑️ Supprimer')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              PriorityBadge(priority: task.priority),
              StatusBadge(label: task.status.label, color: _statusColor(task.status)),
              if (task.dueDate != null)
                StatusBadge(
                  label: DateFormat('dd/MM').format(task.dueDate!),
                  color: NabuColors.orange,
                ),
              if (task.estimatedMinutes > 0)
                StatusBadge(
                  label: '${task.estimatedMinutes} min',
                  color: NabuColors.electricBlue,
                ),
            ],
          ),
          if (task.subtasks.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...task.subtasks.map(
              (s) => InkWell(
                onTap: () {
                  final list = List<Subtask>.from(task.subtasks);
                  final idx = list.indexWhere((x) => x.id == s.id);
                  if (idx >= 0) {
                    list[idx] = Subtask(id: s.id, title: s.title, done: !s.done);
                    ref
                        .read(tasksProvider(task.projectId).notifier)
                        .upsert(task.copyWith(subtasks: list));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        s.done
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 18,
                        color: s.done ? NabuColors.green : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.title,
                          style: TextStyle(
                            fontSize: 13,
                            decoration:
                                s.done ? TextDecoration.lineThrough : null,
                            color: isDark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo:
        return NabuColors.violet;
      case TaskStatus.inProgress:
        return NabuColors.cyan;
      case TaskStatus.blocked:
        return const Color(0xFFFF5252);
      case TaskStatus.done:
        return NabuColors.green;
    }
  }
}
