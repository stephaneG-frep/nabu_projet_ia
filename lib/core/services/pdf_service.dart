import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import 'database_service.dart';

class PdfService {
  final DatabaseService db;

  PdfService(this.db);

  Future<Uint8List> buildReport(Project project) async {
    final pdf = pw.Document();
    final tasks = db.getTasks(project.id);
    final doneTasks = tasks.where((t) => t.isDone).toList();
    final pendingTasks = tasks.where((t) => !t.isDone).toList();
    final objectives = db.getObjectives(project.id);
    final budget = db.getBudget(project.id);
    final decisions = db.getDecisions(project.id);
    final risks = db.getRisks(project.id);
    final journal = db.getJournal(project.id);

    final progress = tasks.isEmpty
        ? 0.0
        : doneTasks.length / tasks.length * 100;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'NabuProjet IA',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF7C4DFF),
            ),
          ),
          pw.Text(
            'Rapport du projet',
            style: const pw.TextStyle(color: PdfColors.grey600),
          ),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.bottomRight,
        child: pw.Text('Page ${context.pageNumber}',
            style: const pw.TextStyle(color: PdfColors.grey500)),
      ),
      build: (context) => [
        pw.SizedBox(height: 16),
        pw.Text('${project.icon}  ${project.name}',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 26,
              color: PdfColor.fromInt(0xFF1A1233),
            )),
        pw.SizedBox(height: 8),
        pw.Text(project.description.isNotEmpty
            ? project.description
            : 'Aucune description.',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 16),

        _section('🎯 Objectif principal', pw.Text(project.goalSummary.isEmpty ? 'Non défini' : project.goalSummary, style: const pw.TextStyle(fontSize: 12))),
        pw.SizedBox(height: 8),
        _section('🎯 Objectifs secondaires', objectives.where((o) => !o.isMain).isEmpty
            ? pw.Text('Aucun objectif secondaire défini.', style: const pw.TextStyle(fontSize: 12))
            : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: objectives.where((o) => !o.isMain).map((o) => pw.Text('• ${o.title}  [${o.status.label}]', style: const pw.TextStyle(fontSize: 12))).toList())),
        pw.SizedBox(height: 8),

        _section('📈 Progression',
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Progression globale : ${progress.toStringAsFixed(0)}% '
                  '(${doneTasks.length}/${tasks.length} tâches terminées)', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 6),
              pw.Container(
                height: 10,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                padding: pw.EdgeInsets.zero,
                child: pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Container(
                    width: 480 * progress / 100,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF7C4DFF),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ])),
        pw.SizedBox(height: 16),

        _section('✅ Tâches terminées',
            doneTasks.isEmpty
                ? pw.Text('Aucune tâche terminée.', style: const pw.TextStyle(fontSize: 12))
                : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: doneTasks.map((t) => pw.Text('✓ ${t.title}', style: const pw.TextStyle(fontSize: 12))).toList())),
        pw.SizedBox(height: 8),

        _section('⏳ Tâches restantes',
            pendingTasks.isEmpty
                ? pw.Text('Toutes les tâches sont terminées ! 🎉', style: const pw.TextStyle(fontSize: 12))
                : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: pendingTasks.map((t) => pw.Text('• ${t.title}  (${t.priority.label})', style: const pw.TextStyle(fontSize: 12))).toList())),
        pw.SizedBox(height: 8),

        _section('📅 Planning',
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Début : ${_date(project.startDate)}  —  Fin prévue : ${_date(project.endDate)}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Durée estimée : ${project.estimatedDays} jours', style: const pw.TextStyle(fontSize: 12)),
            ])),
        pw.SizedBox(height: 8),

        _section('💰 Budget',
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Budget prévu : ${_money(project.budgetPlanned)}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Dépenses encourues : ${_money(project.budgetSpent)}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Reste disponible : ${_money(project.budgetPlanned - project.budgetSpent)}', style: pw.TextStyle(fontSize: 12, color: project.budgetPlanned - project.budgetSpent < 0 ? PdfColors.red700 : PdfColors.green700)),
              if (budget.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                ...budget.map((b) => pw.Text('${b.isExpense ? '-' : '+'} ${_money(b.amount)} — ${b.label} (${b.category})', style: const pw.TextStyle(fontSize: 12))),
              ],
            ])),
        pw.SizedBox(height: 8),

        _section('⚖️ Décisions',
            decisions.isEmpty
                ? pw.Text('Aucune décision enregistrée.', style: const pw.TextStyle(fontSize: 12))
                : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: decisions.map((d) => pw.Text('• ${d.title} → ${d.finalDecision ?? d.recommendation}', style: const pw.TextStyle(fontSize: 12))).toList())),
        pw.SizedBox(height: 8),

        _section('⚠️ Risques',
            risks.isEmpty
                ? pw.Text('Aucun risque identifié.', style: const pw.TextStyle(fontSize: 12))
                : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: risks.where((r) => !r.isResolved).map((r) => pw.Text('• ${r.title} — ${r.severityLabel} : ${r.solution}', style: const pw.TextStyle(fontSize: 12))).toList())),
        pw.SizedBox(height: 8),

        _section('📔 Journal du projet',
            journal.isEmpty
                ? pw.Text('Aucune entrée.', style: const pw.TextStyle(fontSize: 12))
                : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: journal.take(20).map((j) => pw.Text('• ${_shortDate(j.date)} : ${j.content}', style: const pw.TextStyle(fontSize: 12))).toList())),

        pw.SizedBox(height: 16),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text('📌 Bilan',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColor.fromInt(0xFF7C4DFF))),
        pw.SizedBox(height: 4),
        pw.Text('Prochaine meilleure action : ${project.nextAction.isEmpty ? 'À définir avec l\'assistant IA' : project.nextAction}', style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 4),
        pw.Text('Document généré le ${_fullDate(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
      ],
    ));

    return pdf.save();
  }

  pw.Widget _section(String title, pw.Widget body) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF4F0FF),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
              color: PdfColor.fromInt(0xFF7C4DFF),
            ),
          ),
          pw.SizedBox(height: 4),
          body,
        ],
      ),
    );
  }

  Future<void> share(Project project) async {
    final bytes = await buildReport(project);
    await Printing.sharePdf(
        bytes: bytes, filename: 'rapport_${project.name}.pdf');
  }

  Future<void> print(Project project) async {
    final bytes = await buildReport(project);
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  String _money(double v) => '${v.toStringAsFixed(2)} €';
  String _date(DateTime? d) => d == null ? 'Non définie' : _shortDate(d);
  String _shortDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fullDate(DateTime d) =>
      '${_shortDate(d)} à ${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
}