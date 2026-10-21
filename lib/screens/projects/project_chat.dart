import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../ai/ai_settings_screen.dart';

class ProjectChatScreen extends ConsumerStatefulWidget {
  const ProjectChatScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectChatScreen> createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends ConsumerState<ProjectChatScreen> {
  static const _suggestions = [
    'Que dois-je faire maintenant ?',
    'Je suis bloqué 🆘',
    'Adapte mon planning',
    'Explique ma prochaine tâche',
    'Fais le point 📊',
  ];

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _busy = false;

  bool get _offline {
    final ai = ref.read(aiSettingsProvider);
    if (!ai.useAI) return true;
    if (ai.provider == 'ollama') return ai.baseUrl.isEmpty;
    return (ref.read(aiKeysProvider)[ai.provider] ?? '').isEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _clearConversation() async {
    final ok = await confirmDialog(
      context,
      title: 'Effacer la conversation ?',
      message:
          'Tous les messages de chat de ce projet seront supprimés définitivement.',
      confirmLabel: 'Effacer',
    );
    if (!ok || !mounted) return;
    ref.read(messagesProvider(widget.projectId).notifier).clear();
    showSnack(context, 'Conversation effacée');
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AISettingsScreen()),
    );
  }

  String _localReply(Project project, String message) {
    final lower = message.toLowerCase();
    final tasks = ref.read(tasksProvider(project.id));
    final done = tasks.where((t) => t.isDone).length;
    final next = project.nextAction.isEmpty
        ? 'définir ta prochaine action concrète'
        : project.nextAction;
    if (lower.contains('que dois-je faire') ||
        lower.contains('quoi faire') ||
        lower.contains('prochaine action')) {
      return 'D\'après ton projet « ${project.name} », la meilleure prochaine '
          'action est : « $next ». Commence par ça !';
    }
    if (lower.contains('bloqué') || lower.contains('blocage')) {
      return 'Quelques pistes : 1) découpe la tâche en plus petits morceaux, '
          '2) demande de l\'aide à quelqu\'un, 3) essaie un autre angle. '
          'Veux-tu que je l\'ajoute au journal du projet ?';
    }
    if (lower.contains('adapt') ||
        lower.contains('réorganis') ||
        lower.contains('planning') ||
        lower.contains('plan ')) {
      return 'Pour réorganiser ton planning, dis-moi ta nouvelle contrainte '
          '(ex: j\'ai seulement 5 jours, j\'ai moins de budget). Je peux alors '
          'adapter le projet.';
    }
    if (lower.contains('explique') || lower.contains('détaille')) {
      return 'Explique-moi la tâche qui te bloque et je te la détaillerai '
          'pas à pas.';
    }
    if (lower.contains('point') || lower.contains('bilan')) {
      return 'Bilan de « ${project.name} » : $done/${tasks.length} tâches '
          'terminées. Reste concentré sur la prochaine action : « $next ».';
    }
    return 'Je suis ton chef de projet hors ligne. Dis-moi par exemple '
        '« Que dois-je faire maintenant ? », « Je suis bloqué » ou '
        '« Fais le point ».';
  }

  Future<void> _send(String text) async {
    if (_busy) return;
    final content = text.trim();
    if (content.isEmpty) return;

    Project? project;
    for (final p in ref.read(projectsProvider)) {
      if (p.id == widget.projectId) {
        project = p;
        break;
      }
    }
    if (project == null) {
      showSnack(context, 'Projet introuvable', error: true);
      return;
    }

    FocusScope.of(context).unfocus();
    ref.read(messagesProvider(widget.projectId).notifier).add(ChatMessage(
          projectId: widget.projectId,
          role: 'user',
          content: content,
        ));
    _controller.clear();
    _scrollToBottom();
    setState(() => _busy = true);

    final ai = AIAssistant(
      ref.read(databaseProvider),
      ref.read(aiSettingsProvider),
      ref.read(aiKeysProvider),
    );

    String reply;
    bool isError = false;
    if (!_offline) {
      try {
        final resp = await ai.chat(project, content);
        if (resp.ok && resp.text.isNotEmpty) {
          reply = resp.text;
        } else {
          reply = resp.error ?? 'Impossible de contacter l\'IA. Réessaie plus tard.';
          isError = true;
        }
      } catch (_) {
        reply = 'Impossible de contacter l\'IA. Vérifie ta connexion.';
        isError = true;
      }
    } else {
      reply = _localReply(project, content);
    }

    if (!mounted) return;
    setState(() => _busy = false);
    ref.read(messagesProvider(widget.projectId).notifier).add(ChatMessage(
          projectId: widget.projectId,
          role: 'assistant',
          content: reply,
          isError: isError,
        ));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Project? project;
    for (final p in ref.watch(projectsProvider)) {
      if (p.id == widget.projectId) {
        project = p;
        break;
      }
    }
    final messages = ref.watch(messagesProvider(widget.projectId));
    final offline = _offline;

    return AppBackground(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project?.name ?? 'Chat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  color: isDark ? Colors.white : const Color(0xFF1A1233),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Chef de projet IA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          actions: [
            if (messages.isNotEmpty)
              IconButton(
                tooltip: 'Effacer la conversation',
                onPressed: _clearConversation,
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: project == null
              ? EmptyState(
                  icon: Icons.folder_off_outlined,
                  message: 'Projet introuvable',
                  subMessage: 'Ce projet a peut-être été supprimé.',
                  action: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Retour'),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _chatList(context, isDark, project, messages, offline),
                    ),
                    _inputArea(context, project),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _chatList(
    BuildContext context,
    bool isDark,
    Project project,
    List<ChatMessage> messages,
    bool offline,
  ) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        if (offline) ...[
          _offlineBanner(context),
          const SizedBox(height: 10),
        ],
        if (messages.isEmpty && !_busy && !offline) _welcomeCard(project),
        if (messages.isEmpty && !_busy && offline) const SizedBox(height: 4),
        ...messages.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChatBubble(message: m),
            )),
        if (_busy) const _TypingBubble(),
      ],
    );
  }

  Widget _welcomeCard(Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssistantAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bonjour ! Je suis le chef de projet IA de « ${project.name} ». '
              'Pose-moi une question, par exemple « Que dois-je faire maintenant ? ».',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.white : const Color(0xFF1A1233),
              ),
            ),
          ),
        ],
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
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: NabuColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les fonctionnalités IA nécessitent une connexion à un fournisseur '
              'IA. Ce chat fonctionnera avec des réponses hors ligne.',
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark ? Colors.white : const Color(0xFF5D4A00),
              ),
            ),
          ),
          TextButton(
            onPressed: _openSettings,
            child: const Text('Configurer'),
          ),
        ],
      ),
    );
  }

  Widget _inputArea(BuildContext context, Project project) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF171031) : Colors.white)
            .withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _suggestions
                  .map((s) => _suggestionChip(context, s))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1A1233),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Pose ta question à Léon...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _send(_controller.text),
                ),
              ),
              const SizedBox(width: 8),
              _SendButton(enabled: !_busy, onPressed: () => _send(_controller.text)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _send(label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NabuColors.violet.withValues(alpha: isDark ? 0.22 : 0.1),
                NabuColors.electricBlue.withValues(alpha: isDark ? 0.18 : 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: NabuColors.violet.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 13, color: NabuColors.cyan),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1233),
                ),
              ),
            ],
          ),
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