import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

/// Local persistence layer using Hive.
/// Each collection is stored as a box of `Map<String, dynamic>` (JSON plain objects)
/// keyed by the entity id. This avoids type-adapter code-generation complexity and
/// keeps the storage future-proof.
class DatabaseService {
  static const _boxes = {
    'projects': true,
    'tasks': true,
    'objectives': true,
    'messages': true,
    'notes': true,
    'budget': true,
    'decisions': true,
    'risks': true,
    'journal': true,
    'resources': true,
    'milestones': true,
    'settings': true,
    'onboarding': true,
  };

  Box<Map> _box(String name) => Hive.box<Map>(name);

  /// [path] overrides the storage directory (used by tests, where the
  /// platform app directory is not available).
  Future<void> init({String? path}) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    for (final name in _boxes.keys) {
      await Hive.openBox<Map>(name);
    }
  }

  // ---- GENERIC JSON MAP HELPERS ----

  void _put(String box, String key, Map<String, dynamic> json) =>
      _box(box).put(key, json);

  List<Map<String, dynamic>> _values(String box) =>
      _box(box).values.map((e) => Map<String, dynamic>.from(e)).toList();

  Map<String, dynamic>? _get(String box, String key) {
    final v = _box(box).get(key);
    return v == null ? null : Map<String, dynamic>.from(v);
  }

  void _delete(String box, String key) => _box(box).delete(key);

  // ---- PROJECTS ----

  List<Project> getAllProjects() =>
      _values('projects').map(Project.fromJson).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Project? getProject(String id) {
    final js = _get('projects', id);
    return js == null ? null : Project.fromJson(js);
  }

  void saveProject(Project p) => _put('projects', p.id, p.toJson());

  /// Boxes whose entries belong to a project (deleted with it).
  static const _projectBoxes = [
    'tasks',
    'objectives',
    'messages',
    'notes',
    'budget',
    'decisions',
    'risks',
    'journal',
    'resources',
    'milestones',
  ];

  void deleteProject(String id) {
    _delete('projects', id);
    for (final box in _projectBoxes) {
      _box(box).deleteAll(_idsForProject(box, id));
    }
  }

  List<String> _idsForProject(String box, String projectId) => _box(box)
      .values
      .where((e) => (e['projectId'] as String?) == projectId)
      .map((e) => e['id'] as String)
      .toList();

  // ---- TASKS ----

  List<Task> getTasks(String projectId) {
    final all = _values('tasks')
        .where((e) => (e['projectId'] as String?) == projectId)
        .map(Task.fromJson)
        .toList();
    all.sort((a, b) {
      final c = a.order.compareTo(b.order);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });
    return all;
  }

  Task? getTask(String id) {
    final js = _get('tasks', id);
    return js == null ? null : Task.fromJson(js);
  }

  void saveTask(Task t) => _put('tasks', t.id, t.toJson());

  void deleteTask(String id) => _delete('tasks', id);

  // ---- OBJECTIVES ----

  List<Objective> getObjectives(String projectId) =>
      _values('objectives')
          .where((e) => (e['projectId'] as String?) == projectId)
          .map(Objective.fromJson)
          .toList();

  void saveObjective(Objective o) => _put('objectives', o.id, o.toJson());

  void deleteObjective(String id) => _delete('objectives', id);

  // ---- MESSAGES ----

  List<ChatMessage> getMessages(String projectId) {
    final all = _values('messages')
        .where((e) => (e['projectId'] as String?) == projectId)
        .map(ChatMessage.fromJson)
        .toList();
    all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return all;
  }

  void saveMessage(ChatMessage m) => _put('messages', m.id, m.toJson());

  void clearMessages(String projectId) {
    _box('messages').deleteAll(_idsForProject('messages', projectId));
  }

  // ---- NOTES ----

  List<Note> getNotes(String projectId) {
    final all = _values('notes')
        .where((e) => (e['projectId'] as String?) == projectId)
        .map(Note.fromJson)
        .toList();
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  void saveNote(Note n) => _put('notes', n.id, n.toJson());

  void deleteNote(String id) => _delete('notes', id);

  // ---- BUDGET ----

  List<BudgetItem> getBudget(String projectId) {
    final all = _values('budget')
        .where((e) => (e['projectId'] as String?) == projectId)
        .map(BudgetItem.fromJson)
        .toList();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  double budgetPlannedFor(String projectId) {
    double planned = 0;
    for (final e in _box('budget').values) {
      if ((e['projectId'] as String?) == projectId &&
          e['isExpense'] == false) {
        planned += (e['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    return planned;
  }

  double budgetSpentFor(String projectId) {
    double spent = 0;
    for (final e in _box('budget').values) {
      if ((e['projectId'] as String?) == projectId && e['isExpense'] == true) {
        spent += (e['amount'] as num?)?.toDouble() ?? 0;
      }
    }
    return spent;
  }

  void saveBudgetItem(BudgetItem b) => _put('budget', b.id, b.toJson());

  void deleteBudgetItem(String id) => _delete('budget', id);

  // ---- DECISIONS ----

  List<Decision> getDecisions(String projectId) {
    final all = _values('decisions')
        .where((e) => (e['projectId'] as String?) == projectId)
        .map(Decision.fromJson)
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  void saveDecision(Decision d) => _put('decisions', d.id, d.toJson());

  void deleteDecision(String id) => _delete('decisions', id);

  // ---- RISKS ----

  List<Risk> getRisks(String projectId) => _values('risks')
      .where((e) => (e['projectId'] as String?) == projectId)
      .map(Risk.fromJson)
      .toList();

  void saveRisk(Risk r) => _put('risks', r.id, r.toJson());

  void deleteRisk(String id) => _delete('risks', id);

  // ---- JOURNAL ----

  List<JournalEntry> getJournal(String projectId) {
    final all = _values('journal')
        .where((e) => (e['projectId'] as String?) == projectId)
        .map(JournalEntry.fromJson)
        .toList();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  void saveJournalEntry(JournalEntry j) => _put('journal', j.id, j.toJson());

  // ---- RESOURCES ----

  List<ResourceItem> getResources(String projectId) {
    final all = _values('resources')
        .where((e) => (e['projectId'] as String?) == projectId)
        .map(ResourceItem.fromJson)
        .toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  void saveResource(ResourceItem r) => _put('resources', r.id, r.toJson());

  void deleteResource(String id) => _delete('resources', id);

  // ---- MILESTONES ----

  List<Milestone> getMilestones(String projectId) {
    final all = _values('milestones')
        .where((e) => (e['projectId'] as String?) == projectId)
        .map(Milestone.fromJson)
        .toList();
    all.sort((a, b) => a.date.compareTo(b.date));
    return all;
  }

  void saveMilestone(Milestone m) => _put('milestones', m.id, m.toJson());

  // ---- SETTINGS ----

  SettingsData getSettings() {
    final js = _get('settings', 'settings');
    return js == null ? SettingsData() : SettingsData.fromJson(js);
  }

  void saveSettings(SettingsData s) => _put('settings', 'settings', s.toJson());

  AISettings getAISettings() {
    final js = _get('settings', 'ai');
    return js == null ? AISettings() : AISettings.fromJson(js);
  }

  void saveAISettings(AISettings a) =>
      _put('settings', 'ai', a.toJson());

  /// API keys saved in plain text by versions before 1.0.1.
  /// Only read for the one-time migration to [KeyStorageService].
  Map<String, String>? getLegacyAIKeys() {
    final js = _get('settings', 'aikeys');
    return js?.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<void> deleteLegacyAIKeys() async {
    await _box('settings').delete('aikeys');
    // Rewrite the box file so the plain-text keys don't linger on disk.
    await _box('settings').compact();
  }

  bool isOnboardingDone() {
    final js = _get('settings', 'onboarding');
    return js?['done'] == true;
  }

  void setOnboardingDone() =>
      _put('settings', 'onboarding', {'done': true});
}