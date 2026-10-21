import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/key_storage_service.dart';

/// Must be overridden with an initialized instance (see main.dart): an
/// uninitialized DatabaseService would crash on first access to a Hive box.
final databaseProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

class AppStateNotifier extends StateNotifier<SettingsData> {
  final DatabaseService _db;
  AppStateNotifier(this._db) : super(_db.getSettings());

  void setDarkMode(bool value) {
    state = SettingsData(
        darkMode: value,
        userName: state.userName.isNotEmpty ? state.userName : '👋');
    _db.saveSettings(state);
  }

  void setUserName(String name) {
    state = SettingsData(darkMode: state.darkMode, userName: name);
    _db.saveSettings(state);
  }

  void load() {
    state = _db.getSettings();
  }
}

final settingsProvider =
    StateNotifierProvider<AppStateNotifier, SettingsData>((ref) {
  final db = ref.watch(databaseProvider);
  return AppStateNotifier(db);
});

class AIStateNotifier extends StateNotifier<AISettings> {
  final DatabaseService _db;
  AIStateNotifier(this._db) : super(_db.getAISettings());

  void update(AISettings s) {
    state = s;
    _db.saveAISettings(s);
  }

  void load() {
    state = _db.getAISettings();
  }
}

final aiSettingsProvider =
    StateNotifierProvider<AIStateNotifier, AISettings>((ref) {
  final db = ref.watch(databaseProvider);
  final n = AIStateNotifier(db);
  Future.microtask(n.load);
  return n;
});

final keyStorageProvider =
    Provider<KeyStorageService>((ref) => KeyStorageService());

/// API keys kept in memory. Loaded from secure storage in main.dart and
/// updated by the AI settings screen, so changes apply without a restart.
final aiKeysProvider = StateProvider<Map<String, String>>((ref) => const {});

class ProjectListNotifier extends StateNotifier<List<Project>> {
  final DatabaseService _db;
  ProjectListNotifier(this._db) : super(_db.getAllProjects());

  void refresh() => state = _db.getAllProjects();

  void upsert(Project p) {
    _db.saveProject(p);
    refresh();
  }

  void remove(String id) {
    _db.deleteProject(id);
    refresh();
  }
}

final projectsProvider =
    StateNotifierProvider<ProjectListNotifier, List<Project>>((ref) {
  final db = ref.watch(databaseProvider);
  return ProjectListNotifier(db);
});

final projectByIdProvider =
    Provider.family<Project?, String>((ref, id) {
  return ref.watch(databaseProvider).getProject(id);
});

class TasksNotifier extends StateNotifier<List<Task>> {
  final DatabaseService _db;
  final String projectId;
  TasksNotifier(this._db, this.projectId) : super([]) {
    _load();
  }

  void _load() => state = _db.getTasks(projectId);

  void upsert(Task t) {
    _db.saveTask(t);
    _load();
  }

  void remove(String id) {
    _db.deleteTask(id);
    _load();
  }
}

final tasksProvider =
    StateNotifierProvider.family<TasksNotifier, List<Task>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return TasksNotifier(db, id);
});

class ObjectivesNotifier extends StateNotifier<List<Objective>> {
  final DatabaseService _db;
  final String projectId;
  ObjectivesNotifier(this._db, this.projectId) : super([]) {
    _load();
  }

  void _load() => state = _db.getObjectives(projectId);

  void upsert(Objective o) {
    _db.saveObjective(o);
    _load();
  }

  void remove(String id) {
    _db.deleteObjective(id);
    _load();
  }
}

final objectivesProvider = StateNotifierProvider.family<
    ObjectivesNotifier, List<Objective>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return ObjectivesNotifier(db, id);
});

class MessagesNotifier extends StateNotifier<List<ChatMessage>> {
  final DatabaseService _db;
  final String projectId;
  MessagesNotifier(this._db, this.projectId) : super([]) {
    _load();
  }

  void _load() => state = _db.getMessages(projectId);

  void add(ChatMessage m) {
    _db.saveMessage(m);
    _load();
  }

  void clear() {
    _db.clearMessages(projectId);
    _load();
  }
}

final messagesProvider = StateNotifierProvider.family<
    MessagesNotifier, List<ChatMessage>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return MessagesNotifier(db, id);
});

class NotesNotifier extends StateNotifier<List<Note>> {
  final DatabaseService _db;
  final String projectId;
  NotesNotifier(this._db, this.projectId) : super([]) {
    _load();
  }

  void _load() => state = _db.getNotes(projectId);

  void upsert(Note n) {
    _db.saveNote(n);
    _load();
  }

  void remove(String id) {
    _db.deleteNote(id);
    _load();
  }
}

final notesProvider =
    StateNotifierProvider.family<NotesNotifier, List<Note>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return NotesNotifier(db, id);
});

class BudgetNotifier extends StateNotifier<List<BudgetItem>> {
  final DatabaseService _db;
  final String projectId;
  BudgetNotifier(this._db, this.projectId) : super([]) {
    _load();
  }

  void _load() {
    state = _db.getBudget(projectId);
  }

  double get spent => _db.budgetSpentFor(projectId);
  double get planned => _db.budgetPlannedFor(projectId);

  void upsert(BudgetItem b) {
    _db.saveBudgetItem(b);
    _load();
  }

  void remove(String id) {
    _db.deleteBudgetItem(id);
    _load();
  }
}

final budgetProvider =
    StateNotifierProvider.family<BudgetNotifier, List<BudgetItem>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return BudgetNotifier(db, id);
});

class DecisionsNotifier extends StateNotifier<List<Decision>> {
  final DatabaseService _db;
  final String projectId;
  DecisionsNotifier(this._db, this.projectId) : super([]) {
    _load();
  }

  void _load() => state = _db.getDecisions(projectId);

  void upsert(Decision d) {
    _db.saveDecision(d);
    _load();
  }

  void remove(String id) {
    _db.deleteDecision(id);
    _load();
  }
}

final decisionsProvider = StateNotifierProvider.family<
    DecisionsNotifier, List<Decision>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return DecisionsNotifier(db, id);
});

class RisksNotifier extends StateNotifier<List<Risk>> {
  final DatabaseService _db;
  final String projectId;
  RisksNotifier(this._db, this.projectId) : super([]) {
    _load();
  }

  void _load() => state = _db.getRisks(projectId);

  void upsert(Risk r) {
    _db.saveRisk(r);
    _load();
  }

  void remove(String id) {
    _db.deleteRisk(id);
    _load();
  }
}

final risksProvider =
    StateNotifierProvider.family<RisksNotifier, List<Risk>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return RisksNotifier(db, id);
});

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  final DatabaseService _db;
  final String projectId;
  JournalNotifier(this._db, this.projectId) : super([]) {
    _load();
  }

  void _load() => state = _db.getJournal(projectId);

  void upsert(JournalEntry j) {
    _db.saveJournalEntry(j);
    _load();
  }
}

final journalProvider = StateNotifierProvider.family<
    JournalNotifier, List<JournalEntry>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return JournalNotifier(db, id);
});

class ResourcesNotifier extends StateNotifier<List<ResourceItem>> {
  final DatabaseService _db;
  final String projectId;
  ResourcesNotifier(this._db, this.projectId) : super([]) {
    _load();
  }

  void _load() => state = _db.getResources(projectId);

  void upsert(ResourceItem r) {
    _db.saveResource(r);
    _load();
  }

  void remove(String id) {
    _db.deleteResource(id);
    _load();
  }
}

final resourcesProvider = StateNotifierProvider.family<
    ResourcesNotifier, List<ResourceItem>, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return ResourcesNotifier(db, id);
});

/// Compute overall progress for a project from its tasks.
double computeProjectProgress(List<Task> tasks) {
  if (tasks.isEmpty) return 0;
  final done = tasks.where((t) => t.isDone).length;
  final inProg = tasks.where((t) => t.status == TaskStatus.inProgress).length;
  return (done + inProg * 0.5) / tasks.length;
}