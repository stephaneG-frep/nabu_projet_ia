part of '../section_screens.dart';

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
