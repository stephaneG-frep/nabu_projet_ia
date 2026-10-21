import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';

part 'sections/objectives_section.dart';
part 'sections/tasks_section.dart';
part 'sections/kanban_screen.dart';
part 'sections/planning_section.dart';
part 'sections/budget_section.dart';
part 'sections/resources_section.dart';
part 'sections/notes_section.dart';
part 'sections/risks_section.dart';
part 'sections/decisions_section.dart';
part 'sections/journal_section.dart';

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
