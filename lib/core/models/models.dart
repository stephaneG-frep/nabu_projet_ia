import 'package:flutter/material.dart';

/// Categories
class ProjectCategory {
  static const Map<String, String> icons = {
    'Informatique': '💻',
    'Apprentissage': '🎓',
    'Bricolage': '🔨',
    'Maison': '🏡',
    'Jardin': '🌱',
    'Professionnel': '💼',
    'Entreprise': '🚀',
    'Créatif': '🎨',
    'Voyage': '✈️',
    'Personnel': '❤️',
    'Autre': '➕',
  };

  static const List<String> all = [
    'Informatique',
    'Apprentissage',
    'Bricolage',
    'Maison',
    'Jardin',
    'Professionnel',
    'Entreprise',
    'Créatif',
    'Voyage',
    'Personnel',
    'Autre',
  ];

  static String iconFor(String category) =>
      icons[category] ?? '➕';
}

/// Project status
enum ProjectStatus {
  active('En cours', Icons.play_circle_fill),
  paused('En pause', Icons.pause_circle_filled),
  completed('Terminé', Icons.check_circle),
  archived('Archivé', Icons.archive);

  final String label;
  final IconData icon;
  const ProjectStatus(this.label, this.icon);
}

/// Task status
enum TaskStatus {
  todo('À faire', Icons.radio_button_unchecked),
  inProgress('En cours', Icons.play_circle_filled),
  blocked('Bloqué', Icons.block),
  done('Terminé', Icons.check_circle);

  final String label;
  final IconData icon;
  const TaskStatus(this.label, this.icon);

  static TaskStatus fromString(String? s) {
    switch (s) {
      case 'done':
        return TaskStatus.done;
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'blocked':
        return TaskStatus.blocked;
      default:
        return TaskStatus.todo;
    }
  }
}

/// Priority levels
enum Priority {
  low('Faible', 1),
  normal('Normale', 2),
  high('Importante', 3),
  urgent('Urgente', 4);

  final String label;
  final int weight;
  const Priority(this.label, this.weight);

  static Priority fromString(String? s) {
    switch (s) {
      case 'low':
        return Priority.low;
      case 'high':
        return Priority.high;
      case 'urgent':
        return Priority.urgent;
      default:
        return Priority.normal;
    }
  }

  Color color(bool isDark) {
    switch (this) {
      case Priority.low:
        return isDark ? const Color(0xFFB0BEC5) : const Color(0xFF78909C);
      case Priority.normal:
        return isDark ? const Color(0xFF81D4FA) : const Color(0xFF0277BD);
      case Priority.high:
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00);
      case Priority.urgent:
        return isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828);
    }
  }
}

class Subtask {
  String id;
  String title;
  bool done;

  Subtask({String? id, required this.title, this.done = false})
      : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  static Subtask fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'],
        title: json['title'] ?? '',
        done: json['done'] ?? false,
      );
}

class Task {
  String id;
  String projectId;
  String title;
  String description;
  Priority priority;
  int estimatedMinutes;
  DateTime? dueDate;
  TaskStatus status;
  String notes;
  List<Subtask> subtasks;
  int order;
  DateTime createdAt;
  DateTime updatedAt;
  String? parentId;

  Task({
    String? id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.priority = Priority.normal,
    this.estimatedMinutes = 60,
    this.dueDate,
    this.status = TaskStatus.todo,
    this.notes = '',
    List<Subtask>? subtasks,
    this.order = 0,
    this.parentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        subtasks = subtasks ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get progress {
    if (subtasks.isEmpty) {
      return status == TaskStatus.done ? 1.0 : 0.0;
    }
    int doneCount = subtasks.where((s) => s.done).length;
    return subtasks.isEmpty ? 0 : doneCount / subtasks.length;
  }

  bool get isDone => status == TaskStatus.done;

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'priority': priority.name,
        'estimatedMinutes': estimatedMinutes,
        'dueDate': dueDate?.toIso8601String(),
        'status': status.name,
        'notes': notes,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'order': order,
        'parentId': parentId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Task fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        projectId: json['projectId'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        priority: Priority.fromString(json['priority'] ?? 'normal'),
        estimatedMinutes: json['estimatedMinutes'] ?? 60,
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'])
            : null,
        status: TaskStatus.fromString(json['status'] ?? 'todo'),
        notes: json['notes'] ?? '',
        subtasks: (json['subtasks'] as List? ?? [])
            .map((e) => Subtask.fromJson(e as Map<String, dynamic>))
            .toList(),
        order: json['order'] ?? 0,
        parentId: json['parentId'],
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
            : DateTime.now(),
      );

  Task copyWith({TaskStatus? status, Priority? priority, String? title,
      String? description, int? estimatedMinutes, DateTime? dueDate,
      String? notes, List<Subtask>? subtasks, int? order, String? parentId}) {
    return Task(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      subtasks: subtasks ?? this.subtasks,
      order: order ?? this.order,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class Objective {
  String id;
  String projectId;
  String title;
  bool isMain;
  TaskStatus status;
  Priority priority;
  double progress;
  DateTime? dueDate;

  Objective({
    String? id,
    required this.projectId,
    required this.title,
    this.isMain = false,
    this.status = TaskStatus.todo,
    this.priority = Priority.normal,
    this.progress = 0,
    this.dueDate,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'isMain': isMain,
        'status': status.name,
        'priority': priority.name,
        'progress': progress,
        'dueDate': dueDate?.toIso8601String(),
      };

  static Objective fromJson(Map<String, dynamic> json) => Objective(
        id: json['id'],
        projectId: json['projectId'] ?? '',
        title: json['title'] ?? '',
        isMain: json['isMain'] ?? false,
        status: TaskStatus.fromString(json['status'] ?? 'todo'),
        priority: Priority.fromString(json['priority'] ?? 'normal'),
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        dueDate: json['dueDate'] != null
            ? DateTime.tryParse(json['dueDate'].toString())
            : null,
      );

  Objective copyWith({String? title, TaskStatus? status, Priority? priority,
      double? progress, DateTime? dueDate}) {
    return Objective(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      isMain: isMain,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class ChatMessage {
  String id;
  String projectId;
  String role; // 'user' | 'assistant'
  String content;
  DateTime timestamp;
  bool isError;

  ChatMessage({
    String? id,
    required this.projectId,
    required this.role,
    required this.content,
    this.isError = false,
    DateTime? timestamp,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'role': role,
        'content': content,
        'isError': isError,
        'timestamp': timestamp.toIso8601String(),
      };

  static ChatMessage fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        projectId: json['projectId'] ?? '',
        role: json['role'] ?? 'user',
        content: json['content'] ?? '',
        isError: json['isError'] ?? false,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class Note {
  String id;
  String projectId;
  String title;
  String content;
  String type; // idea, problem, decision, info, reflection
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    String? id,
    required this.projectId,
    required this.title,
    this.content = '',
    this.type = 'idea',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'content': content,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Note fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        projectId: json['projectId'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        type: json['type'] ?? 'idea',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class BudgetItem {
  String id;
  String projectId;
  String label;
  double amount;
  String category; // material, software, travel, services, other
  bool isExpense;
  DateTime date;

  BudgetItem({
    String? id,
    required this.projectId,
    required this.label,
    required this.amount,
    this.category = 'other',
    this.isExpense = false,
    DateTime? date,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'label': label,
        'amount': amount,
        'category': category,
        'isExpense': isExpense,
        'date': date.toIso8601String(),
      };

  static BudgetItem fromJson(Map<String, dynamic> json) => BudgetItem(
        id: json['id'],
        projectId: json['projectId'] ?? '',
        label: json['label'] ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        category: json['category'] ?? 'other',
        isExpense: json['isExpense'] ?? false,
        date: json['date'] != null
            ? DateTime.tryParse(json['date']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class Decision {
  String id;
  String projectId;
  String title;
  String description;
  String choice1;
  String choice2;
  String? finalDecision;
  String recommendation;
  String pros;
  String cons;
  String risks;
  String impact;
  String categories;
  DateTime createdAt;

  Decision({
    String? id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.choice1 = '',
    this.choice2 = '',
    this.finalDecision,
    this.recommendation = '',
    this.pros = '',
    this.cons = '',
    this.risks = '',
    this.impact = '',
    this.categories = '',
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'description': description,
        'choice1': choice1,
        'choice2': choice2,
        'finalDecision': finalDecision,
        'recommendation': recommendation,
        'pros': pros,
        'cons': cons,
        'risks': risks,
        'impact': impact,
        'categories': categories,
        'createdAt': createdAt.toIso8601String(),
      };

  static Decision fromJson(Map<String, dynamic> json) => Decision(
        id: json['id'],
        projectId: json['projectId'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        choice1: json['choice1'] ?? '',
        choice2: json['choice2'] ?? '',
        finalDecision: json['finalDecision'],
        recommendation: json['recommendation'] ?? '',
        pros: json['pros'] ?? '',
        cons: json['cons'] ?? '',
        risks: json['risks'] ?? '',
        impact: json['impact'] ?? '',
        categories: json['categories'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class Risk {
  String id;
  String projectId;
  String title;
  String probability; // low, medium, high
  String impact; // low, medium, high
  String solution;
  bool isResolved;
  DateTime createdAt;

  Risk({
    String? id,
    required this.projectId,
    required this.title,
    this.probability = 'medium',
    this.impact = 'medium',
    this.solution = '',
    this.isResolved = false,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  String get severityLabel {
    int p = probability == 'high' ? 3 : (probability == 'medium' ? 2 : 1);
    int i = impact == 'high' ? 3 : (impact == 'medium' ? 2 : 1);
    if (p * i >= 6) return 'Critique';
    if (p * i >= 3) return 'Modéré';
    return 'Faible';
  }

  Color severityColor(bool isDark) {
    switch (severityLabel) {
      case 'Critique':
        return isDark ? const Color(0xFFFF8A80) : const Color(0xFFC62828);
      case 'Modéré':
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00);
      default:
        return isDark ? const Color(0xFF80CBC4) : const Color(0xFF00695C);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'probability': probability,
        'impact': impact,
        'solution': solution,
        'isResolved': isResolved,
        'createdAt': createdAt.toIso8601String(),
      };

  static Risk fromJson(Map<String, dynamic> json) => Risk(
        id: json['id'],
        projectId: json['projectId'] ?? '',
        title: json['title'] ?? '',
        probability: json['probability'] ?? 'medium',
        impact: json['impact'] ?? 'medium',
        solution: json['solution'] ?? '',
        isResolved: json['isResolved'] ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class JournalEntry {
  String id;
  String projectId;
  String content;
  DateTime date;
  String type; // info, taskDone, planning, decision, manual

  JournalEntry({
    String? id,
    required this.projectId,
    required this.content,
    DateTime? date,
    this.type = 'manual',
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'content': content,
        'date': date.toIso8601String(),
        'type': type,
      };

  static JournalEntry fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'],
        projectId: json['projectId'] ?? '',
        content: json['content'] ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date']) ?? DateTime.now()
            : DateTime.now(),
        type: json['type'] ?? 'manual',
      );
}

class ResourceItem {
  String id;
  String projectId;
  String title;
  String url;
  String content;
  String type; // link, text, document
  String category;
  DateTime createdAt;

  ResourceItem({
    String? id,
    required this.projectId,
    required this.title,
    this.url = '',
    this.content = '',
    this.type = 'link',
    this.category = 'Documentation',
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'url': url,
        'content': content,
        'type': type,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  static ResourceItem fromJson(Map<String, dynamic> json) => ResourceItem(
        id: json['id'],
        projectId: json['projectId'] ?? '',
        title: json['title'] ?? '',
        url: json['url'] ?? '',
        content: json['content'] ?? '',
        type: json['type'] ?? 'link',
        category: json['category'] ?? 'Documentation',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
      );
}

class Milestone {
  String id;
  String projectId;
  String title;
  DateTime date;
  bool isDone;
  String phase; // idée, préparation, prototype, test, amélioration, finalisation

  Milestone({
    String? id,
    required this.projectId,
    required this.title,
    required this.date,
    this.isDone = false,
    this.phase = 'préparation',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'title': title,
        'date': date.toIso8601String(),
        'isDone': isDone,
        'phase': phase,
      };

  static Milestone fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'],
        projectId: json['projectId'] ?? '',
        title: json['title'] ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date']) ?? DateTime.now()
            : DateTime.now(),
        isDone: json['isDone'] ?? false,
        phase: json['phase'] ?? 'préparation',
      );
}

class Project {
  String id;
  String name;
  String description;
  String category;
  ProjectStatus status;
  String icon;
  int colorSeed;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? startDate;
  DateTime? endDate;
  int estimatedDays;
  String skillLevel;
  String nextAction;
  String goalSummary;
  double budgetPlanned;
  double budgetSpent;

  Project({
    String? id,
    required this.name,
    this.description = '',
    this.category = 'Autre',
    this.status = ProjectStatus.active,
    this.icon = '🚀',
    this.colorSeed = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.startDate,
    this.endDate,
    this.estimatedDays = 30,
    this.skillLevel = 'Débutant',
    this.nextAction = '',
    this.goalSummary = '',
    this.budgetPlanned = 0,
    this.budgetSpent = 0,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Project copyWith({
    String? name,
    String? description,
    String? category,
    ProjectStatus? status,
    String? icon,
    String? nextAction,
    String? goalSummary,
    int? estimatedDays,
    String? skillLevel,
    DateTime? startDate,
    DateTime? endDate,
    double? budgetPlanned,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      colorSeed: colorSeed,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      skillLevel: skillLevel ?? this.skillLevel,
      nextAction: nextAction ?? this.nextAction,
      goalSummary: goalSummary ?? this.goalSummary,
      budgetPlanned: budgetPlanned ?? this.budgetPlanned,
      budgetSpent: budgetSpent,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'status': status.name,
        'icon': icon,
        'colorSeed': colorSeed,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'estimatedDays': estimatedDays,
        'skillLevel': skillLevel,
        'nextAction': nextAction,
        'goalSummary': goalSummary,
        'budgetPlanned': budgetPlanned,
        'budgetSpent': budgetSpent,
      };

  static Project fromJson(Map<String, dynamic> json) => Project(
        id: json['id'],
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        category: json['category'] ?? 'Autre',
        status: _statusFromString(json['status'] ?? 'active'),
        icon: json['icon'] ?? '🚀',
        colorSeed: json['colorSeed'] ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
            : DateTime.now(),
        startDate: json['startDate'] != null
            ? DateTime.tryParse(json['startDate'].toString())
            : null,
        endDate: json['endDate'] != null
            ? DateTime.tryParse(json['endDate'].toString())
            : null,
        estimatedDays: json['estimatedDays'] ?? 30,
        skillLevel: json['skillLevel'] ?? 'Débutant',
        nextAction: json['nextAction'] ?? '',
        goalSummary: json['goalSummary'] ?? '',
        budgetPlanned: (json['budgetPlanned'] as num?)?.toDouble() ?? 0,
        budgetSpent: (json['budgetSpent'] as num?)?.toDouble() ?? 0,
      );

  static ProjectStatus _statusFromString(String s) {
    switch (s) {
      case 'paused':
        return ProjectStatus.paused;
      case 'completed':
        return ProjectStatus.completed;
      case 'archived':
        return ProjectStatus.archived;
      default:
        return ProjectStatus.active;
    }
  }
}

class AISettings {
  String provider; // openai, mistral, gemini, claude, ollama
  String model;
  String baseUrl;
  bool useAI;

  AISettings({
    this.provider = 'openai',
    this.model = '',
    this.baseUrl = '',
    this.useAI = true,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'model': model,
        'baseUrl': baseUrl,
        'useAI': useAI,
      };

  /// Values saved by version 1.0.0 that are not valid model IDs (display
  /// labels) or whose model has been shut down. Reset to the provider default.
  static const _legacyModels = {'GPT-4o mini', 'claude-sonnet', 'gemini-2.0-flash'};

  static AISettings fromJson(Map<String, dynamic> json) => AISettings(
        provider: json['provider'] ?? 'openai',
        model: _legacyModels.contains(json['model']) ? '' : json['model'] ?? '',
        baseUrl: json['baseUrl'] ?? '',
        useAI: json['useAI'] ?? true,
      );

  String get providerName {
    switch (provider) {
      case 'openai':
        return 'OpenAI';
      case 'mistral':
        return 'Mistral';
      case 'gemini':
        return 'Google Gemini';
      case 'claude':
        return 'Anthropic Claude';
      case 'ollama':
        return 'Ollama';
      default:
        return 'OpenAI';
    }
  }
}

class SettingsData {
  final bool darkMode;
  final String userName;

  const SettingsData({this.darkMode = true, this.userName = '👋'});

  Map<String, dynamic> toJson() => {'darkMode': darkMode, 'userName': userName};

  static SettingsData fromJson(Map<String, dynamic> json) => SettingsData(
        darkMode: json['darkMode'] ?? true,
        userName: json['userName'] ?? '👋',
      );
}