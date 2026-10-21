part of '../section_screens.dart';

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
