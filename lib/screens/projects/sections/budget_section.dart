part of '../section_screens.dart';

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
