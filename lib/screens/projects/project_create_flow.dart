import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../ai/ai_settings_screen.dart';
import 'project_dashboard.dart';

class ProjectCreateFlowScreen extends ConsumerStatefulWidget {
  final String? initialIdea;
  const ProjectCreateFlowScreen({super.key, this.initialIdea});

  @override
  ConsumerState<ProjectCreateFlowScreen> createState() =>
      _ProjectCreateFlowScreenState();
}

class _ProjectCreateFlowScreenState extends ConsumerState<ProjectCreateFlowScreen> {
  static const _examples = [
    'Je veux apprendre Python',
    'Je veux réorganiser mon jardin',
    'Je veux créer ma micro-entreprise',
    'Je veux organiser un voyage au Japon',
    'Je veux restaurer un vieux meuble',
    'Je veux créer une station météo maison',
  ];

  static const _interviewSystemPrompt = 'Tu es « Léon », le chef de projet IA '
      'bienveillant de NabuProjet IA. Tu accompagnes l\'utilisateur pour '
      'transformer une simple idée en projet concret. Pose UNE ou DEUX questions '
      'importantes à la fois (maximum 3) pour comprendre : son niveau de '
      'compétence, son budget, son temps disponible, sa date souhaitée et ses '
      'difficultés. Fais une courte introduction bienveillante d\'une phrase puis '
      'pose tes questions. Réponds toujours en français, de façon chaleureuse et '
      'concise.';

  final _ideaController = TextEditingController();
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  String _phase = 'idea';
  bool _busy = false;

  String get _phaseLabel {
    switch (_phase) {
      case 'chat':
        return 'Étape 2 · Discussion avec Léon';
      case 'plan':
        return 'Étape 3 · Prêt à créer le plan';
      case 'preparingPlan':
        return 'Création du plan...';
      case 'done':
        return 'Projet créé ✓';
      default:
        return 'Étape 1 · Décris ton idée';
    }
  }
  bool _preparing = false;

  int get _userMessageCount =>
      _messages.where((m) => m.role == 'user').length;

  bool _aiReady(WidgetRef ref) {
    final ai = ref.read(aiSettingsProvider);
    if (!ai.useAI) return false;
    final keys = ref.read(aiKeysProvider);
    if (ai.provider == 'ollama') return ai.baseUrl.isNotEmpty;
    return (keys[ai.provider] ?? '').isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialIdea != null && widget.initialIdea!.isNotEmpty) {
      _ideaController.text = widget.initialIdea!;
    }
  }

  @override
  void dispose() {
    _ideaController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _gatheredIdea() {
    if (_messages.isEmpty) {
      return _ideaController.text.trim();
    }
    final buffer = StringBuffer();
    for (final m in _messages) {
      buffer.writeln('${m.role == 'user' ? 'Moi' : 'Léon'} : ${m.content}');
    }
    return buffer.toString().trim();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _startChat() async {
    final idea = _ideaController.text.trim();
    if (idea.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _messages.add(ChatMessage(projectId: '', role: 'user', content: idea));
      _phase = 'chat';
    });
    _scrollToBottom();
    final ai = AIAssistant(
      ref.read(databaseProvider),
      ref.read(aiSettingsProvider),
      ref.read(aiKeysProvider),
    );
    if (!ai.enabled || !_aiReady(ref)) {
      setState(() {
        _messages.add(ChatMessage(
          projectId: '',
          role: 'assistant',
          content: _offlineIntro(idea),
        ));
      });
      _scrollToBottom();
      return;
    }
    await _askAI();
  }

  Future<void> _sendChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _messages.add(ChatMessage(projectId: '', role: 'user', content: text));
      if (_userMessageCount >= 2) _phase = 'plan';
    });
    _chatController.clear();
    _scrollToBottom();
    final ai = AIAssistant(
      ref.read(databaseProvider),
      ref.read(aiSettingsProvider),
      ref.read(aiKeysProvider),
    );
    if (!ai.enabled || !_aiReady(ref)) {
      setState(() {
        _messages.add(ChatMessage(
          projectId: '',
          role: 'assistant',
          content: _offlineReply(text),
        ));
      });
      _scrollToBottom();
      return;
    }
    await _askAI();
  }

  Future<void> _askAI() async {
    setState(() => _busy = true);
    final ai = AIAssistant(
      ref.read(databaseProvider),
      ref.read(aiSettingsProvider),
      ref.read(aiKeysProvider),
    );
    final history = _messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
    try {
      final resp = await ai.service.chat(
        messages: [
          {'role': 'system', 'content': _interviewSystemPrompt},
          ...history,
        ],
        apiKey: ai.apiKey,
        model: ai.aiSettings.model,
        baseUrl: ai.aiSettings.baseUrl,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _messages.add(ChatMessage(
          projectId: '',
          role: 'assistant',
          content: resp.ok && resp.text.isNotEmpty
              ? resp.text
              : (resp.error ?? 'Impossible de contacter l\'IA.'),
          isError: !resp.ok || resp.text.isEmpty,
        ));
        if (_userMessageCount >= 2) _phase = 'plan';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _messages.add(ChatMessage(
          projectId: '',
          role: 'assistant',
          content: 'Impossible de contacter l\'IA. Vérifie ta connexion.',
          isError: true,
        ));
      });
    }
    _scrollToBottom();
  }

  String _offlineIntro(String idea) {
    return 'Bienvenue ! Je suis Léon, ton chef de projet IA. Pour « $idea », '
        'dis-moi quelques précisions : quel est ton niveau ? Combien de temps '
        'peux-tu y consacrer ? Quel budget ? Ensuite, tu pourras créer ton projet '
        'avec un plan de base.';
  }

  String _offlineReply(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('niveau') ||
        lower.contains('temps') ||
        lower.contains('budget') ||
        lower.contains('journal') ||
        lower.contains('semaine')) {
      return 'Noté ! Je le garde en tête pour la création de ton projet. 🎯 '
          'Continue de préciser ton idée (niveau, temps, budget, date souhaitée) '
          'puis touche « Créer mon projet 🎉 ».';
    }
    return 'Bien reçu et noté. ✅ Pour créer un plan de base sans IA, touche '
        '« Créer mon projet 🎉 » en haut du fil de discussion.';
  }

  Future<void> _createNow({required bool useAI}) async {
    if (_preparing) return;
    setState(() {
      _preparing = true;
      _phase = 'preparingPlan';
    });
    final ideaWithContext = _gatheredIdea();
    ProjectPlan plan;
    if (useAI) {
      final ai = AIAssistant(
        ref.read(databaseProvider),
        ref.read(aiSettingsProvider),
        ref.read(aiKeysProvider),
      );
      try {
        final generated = await ai.generatePlan(ideaWithContext);
        plan = generated ?? fallbackPlan(ideaWithContext);
      } catch (_) {
        plan = fallbackPlan(ideaWithContext);
      }
    } else {
      plan = fallbackPlan(ideaWithContext);
    }
    if (!mounted) return;
    await _persistProject(plan, ideaWithContext);
  }

  Future<void> _persistProject(ProjectPlan plan, String idea) async {
    final now = DateTime.now();
    final project = Project(
      name: plan.name,
      description: plan.description,
      category: plan.category,
      icon: plan.icon,
      colorSeed: ref.read(projectsProvider).length,
      estimatedDays: plan.durationDays,
      skillLevel: plan.skillLevel,
      budgetPlanned: plan.budget.toDouble(),
      goalSummary: plan.goal,
      nextAction: plan.nextAction,
      startDate: now,
      endDate: now.add(Duration(days: plan.durationDays)),
    );
    ref.read(projectsProvider.notifier).upsert(project);

    for (var i = 0; i < plan.objectives.length; i++) {
      ref.read(objectivesProvider(project.id).notifier).upsert(Objective(
            projectId: project.id,
            title: plan.objectives[i],
            isMain: i == 0,
            priority: Priority.high,
          ));
    }

    final tasks = [...plan.tasks]
      ..sort((a, b) => a.dueInDays.compareTo(b.dueInDays));
    for (var i = 0; i < tasks.length; i++) {
      final pt = tasks[i];
      ref.read(tasksProvider(project.id).notifier).upsert(Task(
            projectId: project.id,
            title: pt.title,
            description: pt.description,
            priority: Priority.fromString(pt.priority),
            status: TaskStatus.todo,
            estimatedMinutes: pt.estimatedMinutes,
            dueDate: now.add(Duration(days: pt.dueInDays)),
            order: i,
            subtasks: pt.subtasks.map((s) => Subtask(title: s)).toList(),
          ));
    }

    for (final r in plan.risks) {
      ref.read(risksProvider(project.id).notifier).upsert(Risk(
            projectId: project.id,
            title: r.title,
            probability: r.probability,
            impact: r.impact,
            solution: r.solution,
          ));
    }

    final messages = ref.read(messagesProvider(project.id));
    if (messages.isEmpty) {
      ref.read(messagesProvider(project.id).notifier).add(ChatMessage(
            projectId: project.id,
            role: 'user',
            content: idea.trim(),
          ));
    }
    ref.read(messagesProvider(project.id).notifier).add(ChatMessage(
          projectId: project.id,
          role: 'assistant',
          content: 'Projet « ${plan.name} » créé avec ${tasks.length} tâches '
              'pour environ ${plan.durationDays} jours 🎉\n\n'
              'Prochaine action : ${plan.nextAction}',
        ));

    ref.read(journalProvider(project.id).notifier).upsert(JournalEntry(
          projectId: project.id,
          content: 'Projet créé.',
          type: 'info',
        ));

    if (!mounted) return;
    setState(() => _phase = 'done');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProjectDashboardScreen(projectId: project.id),
      ),
    );
  }

  void _openAISettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AISettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiReady = _aiReady(ref);
    final chatStarted = _messages.isNotEmpty;

    return AppBackground(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _preparing
              ? _preparingView(context)
              : Column(
                  children: [
                    _topBar(context),
                    Expanded(
                      child: chatStarted
                          ? _chatView(context, isDark, aiReady)
                          : _ideaView(context, isDark, aiReady),
                    ),
                    if (chatStarted) _inputBar(context),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : const Color(0xFF1A1233),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Une idée, un projet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1233),
                  ),
                ),
                Text(
                  _preparing ? 'Création en cours...' : _phaseLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ideaView(BuildContext context, bool isDark, bool aiReady) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        if (!aiReady) ...[
          _offlineBanner(context),
          const SizedBox(height: 16),
        ],
        Text(
          'Une idée, un projet',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: isDark ? Colors.white : const Color(0xFF1A1233),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Décris ton idée en quelques mots. Léon, ton chef de projet IA, '
          's\'occupe du reste.',
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: isDark
                ? Colors.white.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _ideaController,
                minLines: 3,
                maxLines: 6,
                autofocus: true,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isDark ? Colors.white : const Color(0xFF1A1233),
                ),
                decoration: const InputDecoration(
                  hintText: 'Décris ton idée librement... '
                      '(ex: je veux créer une application mobile pour suivre '
                      'mes lectures)',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: isDark ? Colors.white10 : Colors.black12),
              const SizedBox(height: 14),
              Text(
                'Quelques idées pour commencer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _examples
                    .map((e) => _exampleChip(context, e))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GradientButton(
          label: 'Discuter avec mon chef de projet IA ✨',
          icon: Icons.auto_awesome,
          expanded: true,
          loading: _busy,
          onPressed: _startChat,
        ),
        if (!aiReady) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _createNow(useAI: false),
            icon: const Icon(Icons.folder_outlined),
            label: const Text('Créer avec un plan de base (sans IA)'),
          ),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _openAISettings,
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: const Text('Paramètres IA'),
        ),
      ],
    );
  }

  void _fillExample(String label) {
    _ideaController.text = label;
    _ideaController.selection = TextSelection.collapsed(offset: label.length);
  }

  Widget _exampleChip(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _fillExample(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: NabuColors.violet.withValues(alpha: isDark ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NabuColors.violet.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFB79DFF) : NabuColors.deepViolet,
          ),
        ),
      ),
    );
  }

  Widget _offlineBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NabuColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NabuColors.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_outlined, color: NabuColors.amber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Les fonctionnalités IA nécessitent une connexion à un '
                  'fournisseur IA.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF5D4A00),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _openAISettings,
              child: const Text('Configurer mon IA'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatView(BuildContext context, bool isDark, bool aiReady) {
    final canCreate = _userMessageCount >= 2;
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      children: [
        if (!aiReady) ...[
          _offlineBanner(context),
          const SizedBox(height: 10),
        ],
        if (canCreate) _readyBanner(context),
        const SizedBox(height: 6),
        ..._messages.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChatBubble(message: m),
            )),
        if (_busy) const _TypingBubble(),
      ],
    );
  }

  Widget _readyBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NabuColors.turquoise.withValues(alpha: isDark ? 0.18 : 0.12),
            NabuColors.violet.withValues(alpha: isDark ? 0.12 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NabuColors.turquoise.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch_outlined, color: NabuColors.turquoise),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Projet prêt à être créé',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1233),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Créer mon projet 🎉',
            icon: Icons.rocket_launch,
            expanded: true,
            onPressed: () => _createNow(useAI: _aiReady(ref)),
          ),
        ],
      ),
    );
  }

  Widget _inputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF1A1233),
              ),
              decoration: const InputDecoration(
                hintText: 'Écris ta réponse...',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendChat(),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(enabled: !_busy, onPressed: _sendChat),
        ],
      ),
    );
  }

  Widget _preparingView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [NabuColors.magenta, NabuColors.violet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Léon prépare ton projet...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Création des objectifs, des tâches et des risques.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: NabuColors.violet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.role == 'user';
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [NabuColors.violet, NabuColors.electricBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AssistantAvatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            margin: const EdgeInsets.only(right: 24),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: message.isError
                  ? (isDark ? const Color(0xFF4A1515) : const Color(0xFFFDECEC))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white),
              border: Border.all(
                color: message.isError
                    ? NabuColors.red.withValues(alpha: 0.4)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: message.isError
                    ? (isDark ? const Color(0xFFFF8A80) : const Color(0xFFC62828))
                    : (isDark ? Colors.white : const Color(0xFF1A1233)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [NabuColors.magenta, NabuColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        const _AssistantAvatar(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white,
            ),
          ),
          child: const TypingDots(),
        ),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;
  const _SendButton({required this.onPressed, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(27),
        child: InkWell(
          borderRadius: BorderRadius.circular(27),
          onTap: enabled ? onPressed : null,
          child: Ink(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [NabuColors.violet, NabuColors.electricBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(
                  color: NabuColors.violet.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}