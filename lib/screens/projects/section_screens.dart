import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';

enum SectionType {
  objectives('Objectifs', Icons.flag_outlined, 'violet'),
  tasks('Tâches', Icons.checklist, 'blue'),
  planning('Planning', Icons.calendar_month, 'cyan'),
  budget('Budget', Icons.payments_outlined, 'green'),
  resources('Ressources', Icons.menu_book_outlined, 'amber'),
  notes('Notes', Icons.sticky_note_2_outlined, 'orange'),
  risks('Risques', Icons.warning_amber_rounded, 'red'),
  decisions('Décisions', Icons.balance_outlined, 'deepViolet'),
  journal('Journal', Icons.article_outlined, 'green');

  final String label;
  final IconData icon;
  final String colorName;
  const SectionType(this.label, this.icon, this.colorName);

  Color color() {
    switch (colorName) {
      case 'blue':
        return NabuColors.electricBlue;
      case 'cyan':
        return NabuColors.cyan;
      case 'green':
        return NabuColors.green;
      case 'amber':
        return NabuColors.orange;
      case 'orange':
        return NabuColors.orange;
      case 'red':
        return const Color(0xFFFF5252);
      case 'deepViolet':
        return NabuColors.deepViolet;
      default:
        return NabuColors.violet;
    }
  }
}

class ProjectSectionScreen extends ConsumerStatefulWidget {
  final String projectId;
  final SectionType section;
  const ProjectSectionScreen({
    super.key,
    required this.projectId,
    required this.section,
  });

  @override
  ConsumerState<ProjectSectionScreen> createState() =>
      _ProjectSectionScreenState();
}

class _ProjectSectionScreenState extends ConsumerState<ProjectSectionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabC;

  @override
  void initState() {
    super.initState();
    _tabC = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.section.color();

    Widget body;
    switch (widget.section) {
      case SectionType.objectives:
        body = _ObjectivesSection(projectId: widget.projectId);
      case SectionType.tasks:
        body = _TasksSection(projectId: widget.projectId, tabC: _tabC);
      case SectionType.planning:
        body = _PlanningSection(projectId: widget.projectId);
      case SectionType.budget:
        body = _BudgetSection(projectId: widget.projectId);
      case SectionType.resources:
        body = _ResourcesSection(projectId: widget.projectId);
      case SectionType.notes:
        body = _NotesSection(projectId: widget.projectId);
      case SectionType.risks:
        body = _RisksSection(projectId: widget.projectId);
      case SectionType.decisions:
        body = _DecisionsSection(projectId: widget.projectId);
      case SectionType.journal:
        body = _JournalSection(projectId: widget.projectId);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        isDark: isDark,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.section.icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(widget.section.label),
                ],
              ),
              actions: [
                if (widget.section == SectionType.tasks)
                  IconButton(
                    icon: const Icon(Icons.view_kanban_outlined),
                    tooltip: 'Vue Kanban',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProjectKanbanScreen(projectId: widget.projectId),
                      ),
                    ),
                  ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              sliver: SliverToBoxAdapter(child: body),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------- OBJECTIFS -------------------------

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

// ------------------------- TÂCHES -------------------------

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

// ------------------------- KANBAN -------------------------

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

// ------------------------- PLANNING -------------------------

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

// ------------------------- BUDGET -------------------------

class _BudgetSection extends ConsumerWidget {
  final String projectId;
  const _BudgetSection({required this.projectId});

  static const cats = [
    ('matériel', 'Matériel'),
    ('logiciel', 'Logiciel'),
    ('déplacement', 'Déplacement'),
    ('services', 'Services'),
    ('autres', 'Autres'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = ref.watch(budgetProvider(projectId));
    final planned = items.where((b) => !b.isExpense).fold<double>(0, (s, b) => s + b.amount);
    final spent = items.where((b) => b.isExpense).fold<double>(0, (s, b) => s + b.amount);
    final remaining = planned - spent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budget prévu',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black45)),
                      Text('${planned.toStringAsFixed(2)} €',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Dépenses',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black45)),
                      Text('${spent.toStringAsFixed(2)} €',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: NabuColors.rose)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppProgressBar(
                value: planned == 0 ? 0 : (spent / planned).clamp(0.0, 1.0),
                color: remaining < 0
                    ? const Color(0xFFFF5252)
                    : NabuColors.turquoise,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    remaining < 0
                        ? '⚠️ Dépassement : ${remaining.abs().toStringAsFixed(2)} €'
                        : 'Reste disponible : ${remaining.toStringAsFixed(2)} €',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: remaining < 0
                            ? const Color(0xFFFF5252)
                            : NabuColors.green),
                  ),
                  const Text(''),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionTitle(
            title: 'Catégories',
            icon: Icons.category_outlined,
            color: NabuColors.turquoise),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cats.map((c) {
            final catSpent =
                items.where((b) => b.isExpense && b.category == c.$1).fold<double>(0, (s, b) => s + b.amount);
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [NabuColors.turquoise, NabuColors.cyan]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.$2,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  Text('${catSpent.toStringAsFixed(2)} €',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const SectionTitle(
            title: 'Mouvements',
            icon: Icons.list_alt,
            color: NabuColors.turquoise),
        if (items.isEmpty)
          GlassCard(
              child: Text('Aucun mouvement. Ajoute une prévision ou une dépense.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
        else
          ...items.map((b) => GlassCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      b.isExpense
                          ? Icons.trending_down
                          : Icons.trending_up,
                      color: b.isExpense ? NabuColors.rose : NabuColors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(
                              '${cats.where((c) => c.$1 == b.category).map((c) => c.$2).firstOrNull ?? b.category} · ${DateFormat('dd/MM').format(b.date)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45)),
                        ],
                      ),
                    ),
                    Text(
                      '${b.isExpense ? '-' : '+'} ${b.amount.toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: b.isExpense
                            ? NabuColors.rose
                            : NabuColors.green,
                      ),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Ajouter un mouvement',
          icon: Icons.add,
          expanded: true,
          onPressed: () => _addBudget(context, ref),
        ),
      ],
    );
  }

  Future<void> _addBudget(BuildContext context, WidgetRef ref) async {
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    var isExpense = true;
    var category = 'autres';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Dialog(
          backgroundColor: isDark ? const Color(0xFF1F1840) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ajouter un mouvement',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 12),
                TextField(
                  controller: labelCtrl,
                  autofocus: true,
                  decoration:
                      const InputDecoration(labelText: 'Libellé'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Montant (€)'),
                ),
                const SizedBox(height: 10),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                        value: true,
                        label: Text('Dépense'),
                        icon: Icon(Icons.trending_down)),
                    ButtonSegment(
                        value: false,
                        label: Text('Budget'),
                        icon: Icon(Icons.trending_up)),
                  ],
                  selected: {isExpense},
                  onSelectionChanged: (s) =>
                      setSheet(() => isExpense = s.first),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: cats
                      .map((c) => DropdownMenuItem(
                          value: c.$1, child: Text(c.$2)))
                      .toList(),
                  onChanged: (v) => setSheet(() => category = v ?? category),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: 'Enregistrer',
                  icon: Icons.check,
                  expanded: true,
                  onPressed: () {
                    final amount =
                        double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                    if (labelCtrl.text.trim().isEmpty || amount == null) {
                      showSnack(context, 'Libellé et montant requis.',
                          error: true);
                      return;
                    }
                    ref
                        .read(budgetProvider(projectId).notifier)
                        .upsert(BudgetItem(
                          projectId: projectId,
                          label: labelCtrl.text.trim(),
                          amount: amount,
                          category: category,
                          isExpense: isExpense,
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

// ------------------------- RESSOURCES -------------------------

class _ResourcesSection extends ConsumerWidget {
  final String projectId;
  const _ResourcesSection({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resources = ref.watch(resourcesProvider(projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
            title: 'Bibliothèque du projet',
            icon: Icons.menu_book_outlined,
            color: NabuColors.orange),
        if (resources.isEmpty)
          GlassCard(
              child: Text('Aucune ressource. Ajoute des liens, textes ou notes utiles.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
        else
          ...resources.map((r) => GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          r.type == 'link'
                              ? Icons.link
                              : r.type == 'document'
                                  ? Icons.description_outlined
                                  : Icons.notes,
                          color: NabuColors.orange.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'delete') {
                              ref
                                  .read(resourcesProvider(projectId).notifier)
                                  .remove(r.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'delete', child: Text('Supprimer'))
                          ],
                        ),
                      ],
                    ),
                    if (r.category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      StatusBadge(label: r.category, color: NabuColors.orange),
                    ],
                    if (r.content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.content,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black54)),
                    ],
                    if (r.url.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final uri = Uri.tryParse(r.url);
                          if (uri != null && uri.hasScheme) {
                            // launch disabled to avoid permission issues;
                            // show a snack instead
                            if (context.mounted) {
                              showSnack(context, r.url);
                            }
                          }
                        },
                        child: Text(
                          r.url,
                          style: const TextStyle(
                              color: NabuColors.electricBlue,
                              fontSize: 12,
                              decoration: TextDecoration.underline),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              )),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Ajouter une ressource',
          icon: Icons.add_link,
          expanded: true,
          onPressed: () => _addResource(context, ref),
        ),
      ],
    );
  }

  Future<void> _addResource(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    var type = 'link';
    var category = 'Documentation';
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
                const Text('Nouvelle ressource',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'link', label: Text('Lien'), icon: Icon(Icons.link)),
                    ButtonSegment(
                        value: 'text', label: Text('Texte'), icon: Icon(Icons.notes)),
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setSheet(() => type = s.first),
                ),
                const SizedBox(height: 10),
                if (type == 'link')
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Adresse (URL)'),
                  ),
                TextField(
                  controller: contentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Contenu / note'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration:
                      const InputDecoration(labelText: 'Catégorie'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Documentation',
                        child: Text('Documentation')),
                    DropdownMenuItem(
                        value: 'Outil',
                        child: Text('Outil')),
                    DropdownMenuItem(
                        value: 'Référence',
                        child: Text('Référence')),
                    DropdownMenuItem(
                        value: 'Matériel',
                        child: Text('Matériel')),
                    DropdownMenuItem(
                        value: 'Autre',
                        child: Text('Autre')),
                  ],
                  onChanged: (v) =>
                      setSheet(() => category = v ?? category),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: 'Enregistrer',
                  icon: Icons.check,
                  expanded: true,
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) {
                      showSnack(context, 'Titre requis.', error: true);
                      return;
                    }
                    ref
                        .read(resourcesProvider(projectId).notifier)
                        .upsert(ResourceItem(
                          projectId: projectId,
                          title: titleCtrl.text.trim(),
                          url: urlCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          type: type,
                          category: category,
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

// ------------------------- NOTES -------------------------

class _NotesSection extends ConsumerWidget {
  final String projectId;
  const _NotesSection({required this.projectId});

  static const types = [
    ('idea', '💡 Idée'),
    ('problem', '⚠️ Problème'),
    ('decision', '⚖️ Décision'),
    ('info', 'ℹ️ Information'),
    ('reflection', '🤔 Réflexion'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notes = ref.watch(notesProvider(projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
            title: 'Bloc-notes du projet',
            icon: Icons.sticky_note_2_outlined,
            color: NabuColors.orange),
        if (notes.isEmpty)
          GlassCard(
              child: Text('Aucune note. Capte tes idées, problèmes et décisions.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
        else
          ...notes.map((n) => GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          types
                              .where((t) => t.$1 == n.type)
                              .map((t) => t.$2)
                              .firstOrNull ??
                              '💡',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            n.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'delete') {
                              ref
                                  .read(notesProvider(projectId).notifier)
                                  .remove(n.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'delete', child: Text('Supprimer'))
                          ],
                        ),
                      ],
                    ),
                    if (n.content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(n.content,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.black54)),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(n.createdAt)} · ${types.where((t) => t.$1 == n.type).map((t) => t.$2.replaceFirst(RegExp(r'^.. '), '')).firstOrNull ?? ''}',
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Ajouter une note',
          icon: Icons.add,
          expanded: true,
          onPressed: () => _addNote(context, ref),
        ),
      ],
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    var type = 'idea';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Dialog(
          backgroundColor: isDark ? const Color(0xFF1F1840) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouvelle note',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Titre'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentCtrl,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Contenu'),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: types.map((t) {
                    final sel = type == t.$1;
                    return ChoiceChip(
                      label: Text(t.$2),
                      selected: sel,
                      onSelected: (_) => setSheet(() => type = t.$1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: 'Enregistrer',
                  icon: Icons.check,
                  expanded: true,
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) {
                      showSnack(context, 'Titre requis.', error: true);
                      return;
                    }
                    ref
                        .read(notesProvider(projectId).notifier)
                        .upsert(Note(
                          projectId: projectId,
                          title: titleCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          type: type,
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

// ------------------------- RISQUES -------------------------

class _RisksSection extends ConsumerWidget {
  final String projectId;
  const _RisksSection({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final risks = ref.watch(risksProvider(projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
            title: 'Registre des risques',
            icon: Icons.warning_amber_rounded,
            color: Color(0xFFFF5252)),
        if (risks.isEmpty)
          GlassCard(
              child: Text('Aucun risque identifié. Ajoute le premier.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
        else
          ...risks.where((r) => !r.isResolved).map((r) => _RiskCard(risk: r)),
        if (risks.any((r) => r.isResolved)) ...[
          const SizedBox(height: 16),
          const SectionTitle(
              title: 'Risques résolus',
              icon: Icons.verified_outlined,
              color: NabuColors.green),
          ...risks.where((r) => r.isResolved).map((r) => _RiskCard(risk: r)),
        ],
        const SizedBox(height: 20),
        GradientButton(
          label: 'Ajouter un risque',
          icon: Icons.add,
          expanded: true,
          onPressed: () => _addRisk(context, ref),
        ),
      ],
    );
  }

  Future<void> _addRisk(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final solutionCtrl = TextEditingController();
    var probability = 'medium';
    var impact = 'medium';
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
                const Text('Nouveau risque',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                      labelText: 'Risque (ex : budget insuffisant)'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: probability,
                        decoration:
                            const InputDecoration(labelText: 'Probabilité'),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Faible')),
                          DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                          DropdownMenuItem(value: 'high', child: Text('Élevée')),
                        ],
                        onChanged: (v) =>
                            setSheet(() => probability = v ?? probability),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: impact,
                        decoration: const InputDecoration(labelText: 'Impact'),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Faible')),
                          DropdownMenuItem(value: 'medium', child: Text('Important')),
                          DropdownMenuItem(value: 'high', child: Text('Majeur')),
                        ],
                        onChanged: (v) =>
                            setSheet(() => impact = v ?? impact),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: solutionCtrl,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Solution proposée'),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: 'Enregistrer',
                  icon: Icons.check,
                  expanded: true,
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) {
                      showSnack(context, 'Décris le risque.', error: true);
                      return;
                    }
                    ref
                        .read(risksProvider(projectId).notifier)
                        .upsert(Risk(
                          projectId: projectId,
                          title: titleCtrl.text.trim(),
                          probability: probability,
                          impact: impact,
                          solution: solutionCtrl.text.trim(),
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

class _RiskCard extends ConsumerWidget {
  final Risk risk;
  const _RiskCard({required this.risk});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = risk.severityColor(isDark);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  risk.severityLabel,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'resolve') {
                    ref.read(risksProvider(risk.projectId).notifier).upsert(Risk(
                          id: risk.id,
                          projectId: risk.projectId,
                          title: risk.title,
                          probability: risk.probability,
                          impact: risk.impact,
                          solution: risk.solution,
                          isResolved: true,
                          createdAt: risk.createdAt,
                        ));
                  }
                  if (v == 'delete') {
                    ref
                        .read(risksProvider(risk.projectId).notifier)
                        .remove(risk.id);
                  }
                },
                itemBuilder: (_) => [
                  if (!risk.isResolved)
                    const PopupMenuItem(value: 'resolve', child: Text('✅ Résolu')),
                  const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          Text(
            risk.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Probabilité : ${_level(risk.probability)} · Impact : ${_level(risk.impact)}',
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54),
          ),
          if (risk.solution.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('💡 ${risk.solution}', style: const TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  String _level(String s) =>
      s == 'high' ? 'Élevé(e)' : (s == 'medium' ? 'Moyen(ne)' : 'Faible');
}

// ------------------------- DÉCISIONS -------------------------

class _DecisionsSection extends ConsumerWidget {
  final String projectId;
  const _DecisionsSection({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final decisions = ref.watch(decisionsProvider(projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
            title: 'Décisions du projet',
            icon: Icons.balance_outlined,
            color: NabuColors.deepViolet),
        if (decisions.isEmpty)
          GlassCard(
              child: Text('Aucune décision enregistrée.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
        else
          ...decisions.map((d) => GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gavel_outlined,
                            color: NabuColors.deepViolet, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            d.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'delete') {
                              ref
                                  .read(decisionsProvider(projectId).notifier)
                                  .remove(d.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'delete', child: Text('Supprimer'))
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (d.finalDecision != null) ...[
                      StatusBadge(
                          label: 'Décision : ${d.finalDecision}',
                          color: NabuColors.green),
                      const SizedBox(height: 6),
                    ],
                    if (d.recommendation.isNotEmpty)
                      Text('💡 Recommandation : ${d.recommendation}',
                          style: const TextStyle(fontSize: 13)),
                    if (d.pros.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('✅ Pour : ${d.pros}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                    if (d.cons.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('❌ Contre : ${d.cons}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                    if (d.risks.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('⚠️ Risques : ${d.risks}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                    if (d.impact.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('🔁 Impact : ${d.impact}',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ],
                ),
              )),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Nouvelle décision',
          icon: Icons.add,
          expanded: true,
          onPressed: () => _addDecision(context, ref),
        ),
      ],
    );
  }

  Future<void> _addDecision(BuildContext context, WidgetRef ref) async {
    final titleCtrl = TextEditingController();
    final firstCtrl = TextEditingController();
    final secondCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1F1840) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouvelle décision',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: 'Question (ex : Flutter ou React Native ?)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: firstCtrl,
                decoration: const InputDecoration(labelText: 'Option A'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: secondCtrl,
                decoration: const InputDecoration(labelText: 'Option B'),
              ),
              const SizedBox(height: 18),
              GradientButton(
                label: 'Enregistrer la décision',
                icon: Icons.check,
                expanded: true,
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) {
                    showSnack(context, 'Question requise.', error: true);
                    return;
                  }
                  final decision = Decision(
                    projectId: projectId,
                    title: titleCtrl.text.trim(),
                    choice1: firstCtrl.text.trim(),
                    choice2: secondCtrl.text.trim(),
                  );
                  ref
                      .read(decisionsProvider(projectId).notifier)
                      .upsert(decision);
                  // Propose a recommendation via local AI if available
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------- JOURNAL -------------------------

class _JournalSection extends ConsumerWidget {
  final String projectId;
  const _JournalSection({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final journal = ref.watch(journalProvider(projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
            title: 'Journal du projet',
            icon: Icons.article_outlined,
            color: NabuColors.green),
        if (journal.isEmpty)
          GlassCard(
              child: Text('Le journal est vide. Les événements seront enregistrés ici.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black45)))
        else
          ...journal.map((j) {
            final typeIcon = switch (j.type) {
              'taskDone' => Icons.check_circle,
              'planning' => Icons.sync_alt,
              'decision' => Icons.gavel,
              _ => Icons.info_outline,
            };
            final typeColor = switch (j.type) {
              'taskDone' => NabuColors.green,
              'planning' => NabuColors.cyan,
              'decision' => NabuColors.deepViolet,
              _ => NabuColors.violet,
            };
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('d MMMM yyyy').format(j.date),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: typeColor),
                        ),
                        const SizedBox(height: 2),
                        Text(j.content,
                            style: const TextStyle(fontSize: 14, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Ajouter une entrée manuelle',
          icon: Icons.edit_note,
          expanded: true,
          onPressed: () => _addEntry(context, ref),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: () {
            final list = ref.read(journalProvider(projectId));
            final content = list.isEmpty
                ? 'Aucun historique disponible.'
                : list.take(10).map((j) => '• ${DateFormat('d MMM').format(j.date)} : ${j.content}').join('\n');
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('📔 Historique du projet'),
                content: SingleChildScrollView(
                  child: Text(content, style: const TextStyle(height: 1.5)),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Fermer')),
                ],
              ),
            );
          },
          icon: const Icon(Icons.history),
          label: const Text('Voir l’historique'),
        ),
      ],
    );
  }

  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1F1840) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouvelle entrée du journal',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Ex. : J’ai validé la maquette avec l’association.'),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Enregistrer',
                icon: Icons.check,
                expanded: true,
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              ),
            ],
          ),
        ),
      ),
    );
    if (content != null && content.isNotEmpty) {
      ref.read(journalProvider(projectId).notifier).upsert(JournalEntry(
            projectId: projectId,
            content: content,
            type: 'manual',
          ));
    }
  }
}