part of '../section_screens.dart';

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
