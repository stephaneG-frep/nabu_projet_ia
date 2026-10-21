import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'database_service.dart';

class AIException implements Exception {
  final String message;
  final bool invalidKey;
  final bool noInternet;
  const AIException(this.message, {this.invalidKey = false, this.noInternet = false});
  @override
  String toString() => message;
}

class AIResponse {
  final String text;
  final bool ok;
  final String? error;
  const AIResponse.ok(this.text) : ok = true, error = null;
  const AIResponse.error(this.error) : ok = false, text = '';
}

/// Common contract for all AI providers.
abstract class AIService {
  String get name;

  /// Model used when the user leaves the model field empty.
  String get defaultModel;

  /// Test connectivity with the given values (not necessarily saved yet).
  Future<bool> testConnection({
    required String apiKey,
    required String model,
    String baseUrl = '',
  }) async {
    if (apiKey.isEmpty) return false;
    final r = await chat(
      messages: [
        {'role': 'user', 'content': 'Réponds simplement : ok'}
      ],
      apiKey: apiKey,
      model: model,
      baseUrl: baseUrl,
    );
    return r.ok;
  }

  /// Send a plain chat completion (no project context).
  Future<AIResponse> chat({
    required List<Map<String, String>> messages,
    required String apiKey,
    required String model,
    String baseUrl = '',
    double temperature = 0.7,
  });

  /// Send a chat completion with structured / JSON-guided output.
  Future<AIResponse> chatJson({
    required String system,
    required String user,
    required String apiKey,
    required String model,
    String baseUrl = '',
  }) async {
    final resp = await chat(
      messages: [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      apiKey: apiKey,
      model: model,
      baseUrl: baseUrl,
      temperature: 0.4,
    );
    if (!resp.ok) return resp;
    final cleaned = _stripJsonFences(resp.text);
    return AIResponse.ok(cleaned);
  }

  static String _stripJsonFences(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '').replaceFirst(RegExp(r'```$'), '').trim();
    }
    // extract first {...} block
    final start = t.indexOf('{');
    final end = t.lastIndexOf('}');
    if (start >= 0 && end > start) {
      t = t.substring(start, end + 1);
    }
    return t;
  }
}

/// OpenAI (and OpenAI-compatible endpoints)
class OpenAIService extends AIService {
  @override
  String get name => 'OpenAI';

  @override
  String get defaultModel => 'gpt-4o-mini';

  @override
  Future<AIResponse> chat({
    required List<Map<String, String>> messages,
    required String apiKey,
    required String model,
    String baseUrl = '',
    double temperature = 0.7,
  }) async {
    final url = baseUrl.isNotEmpty
        ? '$baseUrl/chat/completions'
        : 'https://api.openai.com/v1/chat/completions';
    try {
      final resp = await http
          .post(Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
              },
              body: jsonEncode({
                'model': model.isNotEmpty ? model : defaultModel,
                'messages': messages,
                'temperature': temperature,
              }))
          .timeout(const Duration(seconds: 60));
      if (resp.statusCode == 401) {
        return const AIResponse.error("Clé API invalide. Vérifie la clé dans les paramètres.");
      }
      if (resp.statusCode == 429) {
        return const AIResponse.error("Quota dépassé. Réessaie plus tard.");
      }
      if (resp.statusCode != 200) {
        return AIResponse.error("Erreur API (${resp.statusCode}) : ${_safeBody(resp.body)}");
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content = data['choices']?[0]?['message']?['content']?.toString() ?? '';
      if (content.isEmpty) return const AIResponse.error("Réponse IA vide.");
      return AIResponse.ok(content);
    } on AIException catch (e) {
      return AIResponse.error(e.message);
    } catch (e) {
      return AIResponse.error("Impossible de contacter l'IA. Vérifie ta connexion Internet.");
    }
  }
}

class MistralService extends AIService {
  @override
  String get name => 'Mistral';

  @override
  String get defaultModel => 'mistral-small-latest';

  @override
  Future<AIResponse> chat({
    required List<Map<String, String>> messages,
    required String apiKey,
    required String model,
    String baseUrl = '',
    double temperature = 0.7,
  }) async {
    final url = 'https://api.mistral.ai/v1/chat/completions';
    try {
      final resp = await http
          .post(Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
              },
              body: jsonEncode({
                'model': model.isNotEmpty ? model : defaultModel,
                'messages': messages,
                'temperature': temperature,
              }))
          .timeout(const Duration(seconds: 60));
      if (resp.statusCode == 401) {
        return const AIResponse.error("Clé API Mistral invalide.");
      }
      if (resp.statusCode != 200) {
        return AIResponse.error("Erreur Mistral (${resp.statusCode}) : ${_safeBody(resp.body)}");
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content = data['choices']?[0]?['message']?['content']?.toString() ?? '';
      if (content.isEmpty) return const AIResponse.error("Réponse IA vide.");
      return AIResponse.ok(content);
    } catch (e) {
      return AIResponse.error("Impossible de contacter Mistral.");
    }
  }
}

class GeminiService extends AIService {
  @override
  String get name => 'Google Gemini';

  @override
  String get defaultModel => 'gemini-3.8-flash';

  @override
  Future<AIResponse> chat({
    required List<Map<String, String>> messages,
    required String apiKey,
    required String model,
    String baseUrl = '',
    double temperature = 0.7,
  }) async {
    final m = model.isNotEmpty ? model : defaultModel;
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent';
    try {
      final contents = messages
          .map((m) => {
                'role': m['role'] == 'assistant' ? 'model' : 'user',
                'parts': [{'text': m['content']}],
              })
          .toList();
      final resp = await http
          .post(Uri.parse(url),
              // Key sent as a header rather than in the URL, so it doesn't
              // end up in proxy or server logs.
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode({
                'contents': contents,
                'generationConfig': {'temperature': temperature},
              }))
          .timeout(const Duration(seconds: 60));
      if (resp.statusCode >= 400) {
        if (resp.statusCode == 400 && resp.body.contains('API key')) {
          return const AIResponse.error("Clé API Gemini invalide.");
        }
        return AIResponse.error("Erreur Gemini (${resp.statusCode})");
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString() ?? '';
      if (text.isEmpty) return const AIResponse.error("Réponse IA vide.");
      return AIResponse.ok(text);
    } catch (e) {
      return AIResponse.error("Impossible de contacter Gemini.");
    }
  }
}

class ClaudeService extends AIService {
  @override
  String get name => 'Anthropic Claude';

  @override
  String get defaultModel => 'claude-opus-5-5';

  /// Chat completion. `temperature` is ignored: current Claude models reject
  /// sampling parameters (HTTP 400).
  @override
  Future<AIResponse> chat({
    required List<Map<String, String>> messages,
    required String apiKey,
    required String model,
    String baseUrl = '',
    double temperature = 0.7,
  }) async {
    const url = 'https://api.anthropic.com/v1/messages';
    try {
      final system = messages.where((m) => m['role'] == 'system').map((m) => m['content'] ?? '').join('\n');
      final userMsgs = messages.where((m) => m['role'] != 'system').toList();
      final m = model.isNotEmpty ? model : defaultModel;
      // Server-side fallback: if the safety classifiers decline a request,
      // the API retries it on a suitable model instead of returning a refusal.
      final useFallback = m == defaultModel;
      final resp = await http
          .post(Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': apiKey,
                'anthropic-version': '2023-06-01',
                if (useFallback) 'anthropic-beta': 'server-side-fallback-2026-07-01',
              },
              body: jsonEncode({
                'model': m,
                'max_tokens': 16000,
                if (system.isNotEmpty) 'system': system,
                'messages': userMsgs,
                if (useFallback) 'fallbacks': 'default',
              }))
          .timeout(const Duration(seconds: 120));
      if (resp.statusCode == 401) {
        return const AIResponse.error("Clé API Claude invalide.");
      }
      if (resp.statusCode != 200) {
        return AIResponse.error("Erreur Claude (${resp.statusCode}) : ${_safeBody(resp.body)}");
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['stop_reason'] == 'refusal') {
        return const AIResponse.error("Claude a refusé de répondre à cette demande.");
      }
      // Keep only text blocks (thinking blocks carry no `text`).
      final content = (data['content'] as List? ?? [])
          .whereType<Map>()
          .where((c) => c['type'] == 'text')
          .map((c) => c['text']?.toString() ?? '')
          .join();
      if (content.isEmpty) return const AIResponse.error("Réponse IA vide.");
      return AIResponse.ok(content);
    } catch (e) {
      return AIResponse.error("Impossible de contacter Claude.");
    }
  }
}

class OllamaService extends AIService {
  @override
  String get name => 'Ollama';

  @override
  String get defaultModel => 'llama3.2';

  /// Ollama needs no key: checks that the server at [baseUrl] answers.
  /// No `localhost` fallback, which would point to the phone itself.
  @override
  Future<bool> testConnection({
    required String apiKey,
    required String model,
    String baseUrl = '',
  }) async {
    if (baseUrl.isEmpty) return false;
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AIResponse> chat({
    required List<Map<String, String>> messages,
    required String apiKey,
    required String model,
    String baseUrl = '',
    double temperature = 0.7,
  }) async {
    final base = baseUrl;
    if (base.isEmpty) {
      return const AIResponse.error("Configure l'adresse de ton serveur Ollama (ex: http://192.168.1.10:11434).");
    }
    try {
      final resp = await http
          .post(Uri.parse('$base/api/chat'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'model': model.isNotEmpty ? model : defaultModel,
                'messages': messages,
                'stream': false,
                'options': {'temperature': temperature},
              }))
          .timeout(const Duration(seconds: 120));
      if (resp.statusCode != 200) {
        return AIResponse.error("Erreur Ollama (${resp.statusCode})");
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final content = data['message']?['content']?.toString() ?? '';
      if (content.isEmpty) return const AIResponse.error("Réponse IA vide.");
      return AIResponse.ok(content);
    } catch (e) {
      return AIResponse.error("Impossible de contacter Ollama. Vérifie l'adresse du serveur.");
    }
  }
}

class AIServiceFactory {
  static AIService forProvider(String provider) {
    switch (provider) {
      case 'mistral':
        return MistralService();
      case 'gemini':
        return GeminiService();
      case 'claude':
        return ClaudeService();
      case 'ollama':
        return OllamaService();
      default:
        return OpenAIService();
    }
  }
}

String _safeBody(String body) {
  if (body.length > 200) return body.substring(0, 200);
  return body;
}

/// Central project-AI coordination logic.
class AIAssistant {
  final DatabaseService db;
  final AISettings aiSettings;
  final Map<String, String> keys;

  AIAssistant(this.db, this.aiSettings, this.keys);

  bool get enabled => aiSettings.useAI;

  AIService get service => AIServiceFactory.forProvider(aiSettings.provider);

  String get apiKey =>
      keys[aiSettings.provider] ?? '';

  Future<AIResponse> chat(Project project, String userMessage) async {
    return service.chat(
      messages: [
        {
          'role': 'system',
          'content': _projectSystemPrompt(project, includeTasks: true),
        },
        {'role': 'user', 'content': userMessage},
      ],
      apiKey: apiKey,
      model: aiSettings.model,
      baseUrl: aiSettings.baseUrl,
    );
  }

  String _projectSystemPrompt(Project project, {bool includeTasks = true}) {
    final tasks = db.getTasks(project.id);
    final done = tasks.where((t) => t.isDone).length;
    final total = tasks.length;
    final progress = total == 0 ? 0 : (done / total * 100).round();
    final notes = db.getNotes(project.id).take(5).map((n) => '- ${n.title}: ${n.content}').join('\n');
    final risks = db.getRisks(project.id).take(5).map((r) => '- ${r.title} (${r.probability}/${r.impact})').join('\n');

    final taskList = includeTasks && tasks.isNotEmpty
        ? tasks
            .take(20)
            .map((t) =>
                '- [${t.status.label}] ${t.title}${t.dueDate != null ? ' (échéance ${t.dueDate!.day}/${t.dueDate!.month})' : ''}${t.isDone ? ' ✅' : ''}')
            .join('\n')
        : '';

    return '''
Tu es le chef de projet IA de NabuProjet IA. Tu aides UNIQUEMENT sur le projet décrit ci-dessous. Réponds en français, de façon concise, concrète et actionnable. Tu as le rôle d'un coach bienveillant qui remet l'utilisateur sur les rails.

PROJET: ${project.name}
DESCRIPTION: ${project.description}
CATÉGORIE: ${project.category}
OBJECTIF: ${project.goalSummary}
PROGRESSION: $progress% ($done/$total tâches terminées)
PROCHAINE ACTION: ${project.nextAction}
OBJECTIFS:
${db.getObjectives(project.id).map((o) => '- ${o.isMain ? '🎯' : ''} ${o.title} [${o.status.label}]').join('\n')}

TÂCHES ($total):
$taskList

NOTES:
$notes

RISQUES:
$risks

Directives:
- Si l'utilisateur est bloqué, propose Solutions rapide/recommandée/alternative.
- Si le planning doit changer, propose une réorganisation concrète.
- Si l'utilisateur dit "que dois-je faire", recommande UNE action précise avec durée estimée.
- Pour une explication de tâche, adapte le langage au niveau de l'utilisateur.
- Pour une décision, présente POUR / CONTRE / RISQUES / IMPACT / RECOMMANDATION.
- Reste toujours concret, jamais générique.
''';
  }

  /// Generate a full project plan from the gathered idea conversation.
  Future<ProjectPlan?> generatePlan(String idea) async {
    final system = '''
Tu es un expert en gestion de projet. À partir de l'idée, génère un plan de projet complet en JSON UNIQUEMENT (sans texte autour). Le JSON doit avoir exactement cette structure:
{
  "name": "nom du projet (court et évocateur)",
  "description": "description en 1-2 phrases",
  "category": "Informatique|Apprentissage|Bricolage|Maison|Jardin|Professionnel|Entreprise|Créatif|Voyage|Personnel|Autre",
  "icon": "emoji représentant le projet",
  "goal": "objectif principal en une phrase",
  "durationDays": nombre entier,
  "skillLevel": "Débutant|Intermédiaire|Confirmé|Expert",
  "budget": nombre entier (0 si gratuit),
  "nextAction": "première action concrète à faire (précise, actionnable)",
  "tasks": [
    {"title": "titre de la tâche", "description": "description brève", "priority": "low|normal|high|urgent", "estimatedMinutes": nombre, "phase": "préparation|prototype|test|amélioration|finalisation", "dueInDays": nombre de jours après le début, "subtasks": ["sous-tâche 1", "sous-tâche 2"]}
  ],
  "objectives": ["objectif principal", "objectif secondaire 1", "objectif secondaire 2"],
  "risks": [{"title": "risque", "probability": "low|medium|high", "impact": "low|medium|high", "solution": "solution proposée"}]
}
Plan: 5 à 14 tâches. Les tâches doivent être progressives et réalistes. En français.
IDÉE DE L'UTILISATEUR: $idea
''';
    final resp = await service.chatJson(
      system: system,
      user: 'Génère le plan de projet pour cette idée.',
      apiKey: apiKey,
      model: aiSettings.model,
      baseUrl: aiSettings.baseUrl,
    );
    if (!resp.ok) return null;
    try {
      final data = jsonDecode(resp.text) as Map<String, dynamic>;
      return ProjectPlan.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}

class ProjectPlan {
  final String name;
  final String description;
  final String category;
  final String icon;
  final String goal;
  final int durationDays;
  final String skillLevel;
  final int budget;
  final String nextAction;
  final List<PlanTask> tasks;
  final List<String> objectives;
  final List<PlanRisk> risks;

  ProjectPlan({
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.goal,
    required this.durationDays,
    required this.skillLevel,
    required this.budget,
    required this.nextAction,
    required this.tasks,
    required this.objectives,
    required this.risks,
  });

  factory ProjectPlan.fromJson(Map<String, dynamic> json) => ProjectPlan(
        name: json['name']?.toString().trim() ?? 'Mon projet',
        description: json['description']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Autre',
        icon: json['icon']?.toString().trim() ?? '🚀',
        goal: json['goal']?.toString() ?? '',
        durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
        skillLevel: json['skillLevel']?.toString() ?? 'Débutant',
        budget: (json['budget'] as num?)?.toInt() ?? 0,
        nextAction: json['nextAction']?.toString() ?? '',
        tasks: (json['tasks'] as List? ?? [])
            .map((e) => PlanTask.fromJson(e as Map<String, dynamic>))
            .toList(),
        objectives: (json['objectives'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        risks: (json['risks'] as List? ?? [])
            .map((e) => PlanRisk.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PlanTask {
  final String title;
  final String description;
  final String priority;
  final int estimatedMinutes;
  final String phase;
  final int dueInDays;
  final List<String> subtasks;

  PlanTask({
    required this.title,
    required this.description,
    required this.priority,
    required this.estimatedMinutes,
    required this.phase,
    required this.dueInDays,
    required this.subtasks,
  });

  factory PlanTask.fromJson(Map<String, dynamic> json) => PlanTask(
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        priority: json['priority']?.toString() ?? 'normal',
        estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 60,
        phase: json['phase']?.toString() ?? 'préparation',
        dueInDays: (json['dueInDays'] as num?)?.toInt() ?? 1,
        subtasks: (json['subtasks'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class PlanRisk {
  final String title;
  final String probability;
  final String impact;
  final String solution;

  PlanRisk({
    required this.title,
    required this.probability,
    required this.impact,
    required this.solution,
  });

  factory PlanRisk.fromJson(Map<String, dynamic> json) => PlanRisk(
        title: json['title']?.toString() ?? 'Risque',
        probability: json['probability']?.toString() ?? 'medium',
        impact: json['impact']?.toString() ?? 'medium',
        solution: json['solution']?.toString() ?? '',
      );
}

/// Generate a plan without AI (fallback heuristic used by "création sans IA").
ProjectPlan fallbackPlan(String idea) {
  final trimmed = idea.trim();
  final name = trimmed.length > 28 ? '${trimmed.substring(0, 28)}…' : trimmed;
  return ProjectPlan(
    name: name,
    description: 'Projet basé sur : "$idea"',
    category: 'Autre',
    icon: '🚀',
    goal: idea,
    durationDays: 30,
    skillLevel: 'Débutant',
    budget: 0,
    nextAction: 'Définir précisément le résultat attendu',
    tasks: [
      PlanTask(title: 'Définir le résultat attendu', description: 'Écrire en quelques phrases ce que tu veux obtenir.',
          priority: 'high', estimatedMinutes: 30, phase: 'préparation', dueInDays: 1, subtasks: const ['Lister les critères de réussite']),
      PlanTask(title: 'Découper en grandes étapes', description: 'Identifier 3 à 5 grandes étapes du projet.',
          priority: 'high', estimatedMinutes: 45, phase: 'préparation', dueInDays: 2, subtasks: const ['Écrire les étapes', 'Les ordonner']),
      PlanTask(title: 'Rassembler les ressources', description: 'Matériel, outils et informations nécessaires.',
          priority: 'normal', estimatedMinutes: 60, phase: 'préparation', dueInDays: 3, subtasks: const ['Faire la liste', 'Vérifier ce qui manque']),
      PlanTask(title: 'Se lancer : première action concrète', description: 'Commencer par la toute première étape simple.',
          priority: 'urgent', estimatedMinutes: 30, phase: 'prototype', dueInDays: 4, subtasks: const ['Réaliser la première action']),
      PlanTask(title: 'Faire le point', description: 'Évaluer la progression et ajuster le plan.',
          priority: 'normal', estimatedMinutes: 30, phase: 'test', dueInDays: 7, subtasks: const ['Ce qui fonctionne', 'Ce qui bloque']),
      PlanTask(title: 'Finaliser', description: 'Terminer les dernières étapes et vérifier le résultat.',
          priority: 'normal', estimatedMinutes: 60, phase: 'finalisation', dueInDays: 10, subtasks: const ['Dernière vérification', 'Clôturer le projet']),
    ],
    objectives: [idea, 'Découper le projet en étapes', 'Terminer la première action'],
    risks: [
      PlanRisk(title: 'Manque de temps', probability: 'medium', impact: 'high', solution: 'Prévoir des créneaux courts et réguliers.'),
      PlanRisk(title: 'Abandon précoce', probability: 'high', impact: 'medium', solution: 'Commencer par des actions très courtes et faciles.'),
    ],
  );
}