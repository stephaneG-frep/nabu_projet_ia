part of '../section_screens.dart';

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
