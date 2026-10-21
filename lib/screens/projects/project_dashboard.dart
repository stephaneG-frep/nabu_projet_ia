import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/pdf_service.dart';
import '../../widgets/shared.dart';
import 'project_chat.dart';
import 'section_screens.dart';

class ProjectDashboardScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDashboardScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDashboardScreen> createState() =>
      _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState
    extends ConsumerState<ProjectDashboardScreen> {
  bool _asking = false;

  Project? _project() {
    final projects = ref.read(projectsProvider);
    for (final p in projects) {
      if (p.id == widget.projectId) return p;
    }
    return null;
  }

  void _navigate(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<AIResponse> _askAI(String message) async {
    final db = ref.read(databaseProvider);
    final aiSettings = ref.read(aiSettingsProvider);
    final keys = ref.read(aiKeysProvider);
    final ai = AIAssistant(db, aiSettings, keys);
    final project = _project();
    if (project == null) {
      return const AIResponse.error("Projet introuvable.");
    }
    try {
      if (!ai.enabled || (aiSettings.provider != 'ollama' && (keys[aiSettings.provider] ?? '').isEmpty)) {
        return AIResponse.ok(_localAnswer(message, project));
      }
      return await ai.chat(project, message);
    } catch (e) {
      return AIResponse.error("Erreur IA : ${e.toString()}");
    }
  }

  String _localAnswer(String message, Project project) {
    final m = message.toLowerCase();
    final taskList = ref.read(tasksProvider(project.id));
    if (m.contains('que dois-je faire') || m.contains("prochaine action")) {
      final next = taskList.where((t) => !t.isDone).toList()
        ..sort((a, b) => b.priority.weight.compareTo(a.priority.weight));
      final t = next.isNotEmpty ? next.first : null;
      final action = t != null
          ? 'La meilleure prochaine action est : « ${t.title} ». Environ ${t.estimatedMinutes} minutes.'
          : project.nextAction.isEmpty
              ? 'Toutes les tâches semblent terminées. Profite-en pour faire le bilan !'
              : 'La meilleure prochaine action est : « ${project.nextAction} ».';
      return action;
    }
    if (m.contains('bloqué') || m.contains('bloque') || m.contains('🆘')) {
      return 'Quelques pistes pour te débloquer :\n1) Découpe la tâche en très petites étapes.\n2) Demande de l’aide ou cherche un tutoriel.\n3) Essaie une autre approche.\n\nVeux-tu enregistrer ce blocage dans le journal du projet ?';
    }
    if (m.contains('adapt') || m.contains('planning') || m.contains('réorgan') || m.contains('jours') || m.contains('temps')) {
      return 'Pour adapter le projet, dis-moi précisément ta nouvelle contrainte (ex : « je n’ai plus que 5 jours »). Je proposerai alors une réorganisation des tâches et des priorités.';
    }
    if (m.contains('explique')) {
      final next = taskList.where((t) => !t.isDone).toList();
      final t = next.isNotEmpty ? next.first : null;
      return t != null
          ? 'Voici comment aborder « ${t.title} » :\n${t.description.isEmpty ? "Commence par identifier le résultat attendu, puis divise en petites étapes." : t.description}\n\nObjectif visé : ${project.goalSummary.isEmpty ? "avancer le projet" : project.goalSummary}.'
          : 'Aucune tâche en attente à expliquer pour le moment.';
    }
    return 'Je suis ton chef de projet. Voici la situation du projet « ${project.name} » :\n• Progression : ${(ref.read(tasksProvider(project.id)).where((t) => t.isDone).length / (taskList.isEmpty ? 1 : taskList.length) * 100).round()}%\n• Prochaine action : ${project.nextAction.isEmpty ? "à définir" : project.nextAction}\n\nDemande-moi par exemple : « Que dois-je faire maintenant ? », « Je suis bloqué » ou « Adapte mon planning ».';
  }

  Future<void> _showAIDialog(String title, String message) async {
    setState(() => _asking = true);
    final resp = await _askAI(message);
    if (!mounted) return;
    setState(() => _asking = false);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NabuColors.magenta.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.auto_awesome, color: NabuColors.magenta),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                child: Text(
                  resp.ok ? resp.text : (resp.error ?? 'Erreur IA.'),
                  style: TextStyle(
                    height: 1.4,
                    color: resp.ok
                        ? null
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (message.contains("prochaine action"))
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          showSnack(context, 'Bonne action, lance-toi ! 🚀');
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('COMMENCER'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final project = _project();
    if (project == null) return;
    showSnack(context, 'Génération du PDF...');
    try {
      final bytes =
          await PdfService(ref.read(databaseProvider)).buildReport(project);
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (e) {
      if (mounted) showSnack(context, 'Impossible de générer le PDF.', error: true);
    }
  }

  void _showEditSheet() {
    final project = _project()!;
    final nameCtrl = TextEditingController(text: project.name);
    final descCtrl = TextEditingController(text: project.description);
    final goalCtrl = TextEditingController(text: project.goalSummary);
    final actionCtrl = TextEditingController(text: project.nextAction);
    final daysCtrl =
        TextEditingController(text: project.estimatedDays.toString());
    final budgetCtrl =
        TextEditingController(text: project.budgetPlanned.toString());
    String category = project.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).brightness == Brightness.dark
                  ? const Color(0xFF1F1840)
                  : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Modifier le projet',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(ctx).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF1A1233))),
                  const SizedBox(height: 16),
                  TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: ProjectCategory.all
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                                '${ProjectCategory.iconFor(c)} $c')))
                        .toList(),
                    onChanged: (v) => setSheet(() => category = v ?? category),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: goalCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Objectif principal')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: actionCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Prochaine action')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                            controller: daysCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Durée (jours)')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                            controller: budgetCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Budget prévu (€)')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: 'Enregistrer',
                    icon: Icons.save_outlined,
                    expanded: true,
                    onPressed: () {
                      ref.read(projectsProvider.notifier).upsert(project.copyWith(
                            name: nameCtrl.text.trim().isEmpty
                                ? project.name
                                : nameCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            category: category,
                            goalSummary: goalCtrl.text.trim(),
                            nextAction: actionCtrl.text.trim(),
                            estimatedDays:
                                int.tryParse(daysCtrl.text) ?? project.estimatedDays,
                            budgetPlanned:
                                double.tryParse(budgetCtrl.text.replaceAll(',', '.')) ??
                                    project.budgetPlanned,
                          ));
                      Navigator.pop(ctx);
                      showSnack(context, 'Projet mis à jour.');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _changeStatus() {
    final project = _project()!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? const Color(0xFF1F1840)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ProjectStatus.values
              .map((s) => ListTile(
                    leading: Icon(s.icon,
                        color: s == project.status
                            ? NabuColors.violet
                            : null),
                    title: Text(s.label),
                    trailing: s == project.status
                        ? const Icon(Icons.check, color: NabuColors.violet)
                        : null,
                    onTap: () {
                      ref.read(projectsProvider.notifier).upsert(
                          project.copyWith(status: s));
                      ref
                          .read(journalProvider(project.id).notifier)
                          .upsert(JournalEntry(
                              projectId: project.id,
                              content: 'Statut changé en « ${s.label} ».',
                              type: 'info'));
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _project();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (project == null) {
      return Scaffold(
        body: AppBackground(
          isDark: isDark,
          child: EmptyState(
            icon: Icons.folder_off_outlined,
            message: 'Projet introuvable',
            subMessage: 'Ce projet a peut-être été supprimé.',
            action: GradientButton(
              label: 'Retour',
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    }

    final tasks = ref.watch(tasksProvider(project.id));
    final progress = computeProjectProgress(tasks);
    final doneCount = tasks.where((t) => t.isDone).length;
    final gradient = AppTheme.projectGradient(project.colorSeed);
    final openTasks = tasks.where((t) => !t.isDone).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        isDark: isDark,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 210,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.white,
                  onPressed: _showEditSheet,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (v) {
                    if (v == 'pdf') _exportPdf();
                    if (v == 'status') _changeStatus();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'pdf',
                        child: Row(children: [
                          Icon(Icons.picture_as_pdf_outlined), SizedBox(width: 8),
                          Text('Rapport PDF')])),
                    PopupMenuItem(value: 'status',
                        child: Row(children: [
                          Icon(Icons.track_changes), SizedBox(width: 8),
                          Text('Changer de statut')])),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(gradient: gradient),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 90, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${project.icon}  ${project.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          project.description.isEmpty
                              ? 'Aucune description'
                              : project.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _chip(
                              Colors.white.withValues(alpha: 0.22),
                              '${ProjectCategory.iconFor(project.category)} ${project.category}',
                            ),
                            const SizedBox(width: 8),
                            _chip(
                              Colors.white.withValues(alpha: 0.22),
                              project.status.label,
                            ),
                            const SizedBox(width: 8),
                            _chip(
                              Colors.white.withValues(alpha: 0.22),
                              'Niveau : ${project.skillLevel}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Progression',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            AnimatedPercent(value: progress, fontSize: 24),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AppProgressBar(value: progress),
                        const SizedBox(height: 8),
                        Text(
                          '$doneCount/${tasks.length} tâches terminées · $openTasks à faire',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                        if (progress >= 1.0 && tasks.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text('🎉 Bravo ! Toutes les tâches sont terminées.'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        NabuColors.violet.withValues(alpha: 0.15),
                        NabuColors.magenta.withValues(alpha: 0.1),
                      ]),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: NabuColors.violet.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flag_outlined,
                                color: NabuColors.violet),
                            const SizedBox(width: 8),
                            const Text('Prochaine meilleure action',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          project.nextAction.isEmpty
                              ? 'Toutes les tâches sont à jour. Demandons à l’IA !'
                              : 'Aujourd’hui : ${project.nextAction}',
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        GradientButton(
                          label: 'Que dois-je faire maintenant ?',
                          icon: Icons.bolt,
                          onPressed: _asking
                              ? () {}
                              : () => _showAIDialog(
                                  'Recommandation de l’IA',
                                  'Quelle est LA meilleure prochaine action, une seule, avec une durée estimée ? (progression ${(progress * 100).round()}%, $openTasks tâches en attente)'),
                          loading: _asking,
                          expanded: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(
                      title: 'Espace projet',
                      icon: Icons.grid_view_rounded,
                      color: NabuColors.electricBlue),
                  _sectionGrid(project),
                  const SizedBox(height: 20),
                  const SectionTitle(
                      title: 'Actions IA',
                      icon: Icons.auto_awesome,
                      color: NabuColors.magenta),
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    NabuColors.violet,
                                    NabuColors.magenta,
                                  ]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.auto_awesome,
                                color: Colors.white),
                          ),
                          title: const Text('Chef de projet IA',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('Discuter, débloquer, adapter',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : Colors.black.withValues(alpha: 0.5))),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              _navigate(ProjectChatScreen(projectId: project.id)),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    NabuColors.orange,
                                    NabuColors.rose,
                                  ]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child:
                                const Icon(Icons.healing_outlined, color: Colors.white),
                          ),
                          title: const Text('🆘 Je suis bloqué',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('Obtenir de l’aide immédiate',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : Colors.black.withValues(alpha: 0.5))),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showBlockedDialog(project),
                        ),
                        const Divider(),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    NabuColors.cyan,
                                    NabuColors.electricBlue,
                                  ]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.sync_alt, color: Colors.white),
                          ),
                          title: const Text('Adapter mon projet',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('Réorganiser selon les nouvelles contraintes',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : Colors.black.withValues(alpha: 0.5))),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showAdaptDialog(project),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigate(ProjectChatScreen(projectId: project.id)),
        backgroundColor: NabuColors.violet,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chef de projet'),
      ),
    );
  }

  Widget _chip(Color bg, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _sectionGrid(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = <(String, IconData, Color, VoidCallback)>[
      ('Objectif', Icons.flag_outlined, NabuColors.violet, () => _openSection(project, SectionType.objectives)),
      ('Tâches', Icons.checklist, NabuColors.electricBlue, () => _openSection(project, SectionType.tasks)),
      ('Planning', Icons.calendar_month, NabuColors.cyan, () => _openSection(project, SectionType.planning)),
      ('Budget', Icons.payments_outlined, NabuColors.turquoise, () => _openSection(project, SectionType.budget)),
      ('Ressources', Icons.menu_book_outlined, isDark ? Colors.amberAccent : Colors.amber.shade900, () => _openSection(project, SectionType.resources)),
      ('Notes', Icons.sticky_note_2_outlined, NabuColors.orange, () => _openSection(project, SectionType.notes)),
      ('Risques', Icons.warning_amber_rounded, const Color(0xFFFF5252), () => _openSection(project, SectionType.risks)),
      ('Décisions', Icons.balance_outlined, NabuColors.deepViolet, () => _openSection(project, SectionType.decisions)),
      ('Journal', Icons.article_outlined, NabuColors.green, () => _openSection(project, SectionType.journal)),
      ('Rapport PDF', Icons.picture_as_pdf_outlined, const Color(0xFF2979FF), () => _exportPdf()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final (label, icon, color, onTap) = items[i];
        return GlassCard(
          padding: const EdgeInsets.all(14),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1233),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSection(Project project, SectionType type) {
    _navigate(ProjectSectionScreen(projectId: project.id, section: type));
  }

  Future<void> _showBlockedDialog(Project project) async {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final response = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor:
            isDark ? const Color(0xFF1F1840) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🆘 Je suis bloqué',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Décris ton blocage...',
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Demander de l’aide',
                icon: Icons.send,
                expanded: true,
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              ),
            ],
          ),
        ),
      ),
    );
    if (response == null || response.isEmpty) return;
    setState(() => _asking = true);
    final resp = await _askAI(
        'Je suis bloqué : "$response". Analyse pourquoi je suis bloqué et propose : Solution rapide, Solution recommandée, Solution alternative. Impact sur le projet ?');
    if (!mounted) return;
    setState(() => _asking = false);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.healing, color: NabuColors.orange),
                  const SizedBox(width: 8),
                  const Text('Aide pour débloquer',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                child: Text(
                  resp.ok ? resp.text : (resp.error ?? "Je n'ai pas pu répondre."),
                  style: const TextStyle(height: 1.5),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  final pr = _project();
                  if (pr != null) {
                    ref
                        .read(journalProvider(pr.id).notifier)
                        .upsert(JournalEntry(
                          projectId: pr.id,
                          content: 'Blocage signalé : $response',
                          type: 'info',
                        ));
                  }
                  Navigator.pop(ctx);
                  showSnack(context, 'Blocage enregistré dans le journal.');
                },
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Enregistrer dans le journal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAdaptDialog(Project project) async {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final response = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor:
            isDark ? const Color(0xFF1F1840) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Adapter mon projet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Ex. : « J’ai seulement 5 jours » / « Cette tâche m’a pris deux fois plus de temps »',
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Proposer une réorganisation',
                icon: Icons.sync_alt,
                expanded: true,
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              ),
            ],
          ),
        ),
      ),
    );
    if (response == null || response.isEmpty) return;
    setState(() => _asking = true);
    final resp = await _askAI(
        'Adapte mon projet à cette nouvelle contrainte : "$response". Propose une réorganisation concrète du planning, des priorités et des tâches restantes.');
    if (!mounted) return;
    setState(() => _asking = false);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sync_alt, color: NabuColors.cyan),
                  const SizedBox(width: 8),
                  const Text('Nouveau plan suggéré',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                child: Text(
                  resp.ok ? resp.text : (resp.error ?? 'Impossible de répondre.'),
                  style: const TextStyle(height: 1.5),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  final pr = _project();
                  if (pr != null) {
                    ref
                        .read(journalProvider(pr.id).notifier)
                        .upsert(JournalEntry(
                          projectId: pr.id,
                          content: 'Planning adapté : $response',
                          type: 'planning',
                        ));
                  }
                  Navigator.pop(ctx);
                  showSnack(context, 'Adaptation enregistrée dans le journal.');
                },
                icon: const Icon(Icons.check),
                label: const Text('Prendre en compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}