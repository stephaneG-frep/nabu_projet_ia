part of '../section_screens.dart';

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
