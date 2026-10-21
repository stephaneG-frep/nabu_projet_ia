import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';

class AISettingsScreen extends ConsumerStatefulWidget {
  const AISettingsScreen({super.key});

  @override
  ConsumerState<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends ConsumerState<AISettingsScreen> {
  final _modelCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();
  final _keyCtrls = <String, TextEditingController>{
    'openai': TextEditingController(),
    'gemini': TextEditingController(),
    'mistral': TextEditingController(),
    'claude': TextEditingController(),
  };
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ai = ref.read(aiSettingsProvider);
      final keys = ref.read(aiKeysProvider);
      _modelCtrl.text = ai.model;
      _baseUrlCtrl.text = ai.baseUrl;
      for (final e in keys.entries) {
        if (_keyCtrls.containsKey(e.key)) {
          _keyCtrls[e.key]!.text = e.value;
        }
      }
    });
  }

  @override
  void dispose() {
    _modelCtrl.dispose();
    _baseUrlCtrl.dispose();
    for (final c in _keyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _selectedProvider {
    final ai = ref.read(aiSettingsProvider);
    return ai.provider;
  }

  Future<void> _assert() async {
    FocusScope.of(context).unfocus();
    final ai = ref.read(aiSettingsProvider);
    final keys = <String, String>{
      for (final e in _keyCtrls.entries) e.key: e.value.text.trim(),
    };

    try {
      await ref.read(keyStorageProvider).save(keys);
    } catch (_) {
      if (!mounted) return;
      showSnack(context, 'Impossible d’enregistrer la clé dans le stockage sécurisé.');
      return;
    }
    ref.read(aiKeysProvider.notifier).state = keys;
    final settings = AISettings(
      provider: ai.provider,
      model: _modelCtrl.text.trim(),
      baseUrl: _baseUrlCtrl.text.trim(),
      useAI: ai.useAI,
    );
    ref.read(aiSettingsProvider.notifier).update(settings);
    if (!mounted) return;
    showSnack(context, 'Paramètres IA enregistrés.');
  }

  /// Tests the values currently on screen, even if not saved yet.
  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final provider = ref.read(aiSettingsProvider).provider;
    final service = AIServiceFactory.forProvider(provider);
    final ok = await service.testConnection(
      apiKey: _keyCtrls[provider]?.text.trim() ?? '',
      model: _modelCtrl.text.trim(),
      baseUrl: _baseUrlCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = ok
          ? 'Connexion réussie. ✅ Le fournisseur répond correctement.'
          : 'Connexion impossible. Vérifie la clé API, le modèle et Internet.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ai = ref.watch(aiSettingsProvider);

    final providers = [
      ('openai', 'OpenAI', '🟢', 'Clé API OpenAI'),
      ('gemini', 'Google Gemini', '🔵', 'Clé API Google'),
      ('mistral', 'Mistral', '🟠', 'Clé API Mistral'),
      ('claude', 'Anthropic Claude', '🟣', 'Clé API Anthropic'),
      ('ollama', 'Ollama', '🤖', 'Serveur local (aucune clé)'),
    ];

    final isLLM = ai.provider != 'ollama';
    final defaultModel = AIServiceFactory.forProvider(ai.provider).defaultModel;

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
                  onPressed: () => Navigator.pop(context)),
              title: const Text('Fournisseur IA'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Activer l’IA',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text(
                        'Si désactivé, l’app reste utilisable hors ligne avec un assistant local.'),
                    value: ai.useAI,
                    activeThumbColor: NabuColors.violet,
                    onChanged: (v) {
                      ref.read(aiSettingsProvider.notifier).update(
                            AISettings(
                              provider: ai.provider,
                              model: ai.model,
                              baseUrl: ai.baseUrl,
                              useAI: v,
                            ),
                          );
                    },
                  ),
                  const SizedBox(height: 12),
                  const SectionTitle(
                      title: 'Choisir ton fournisseur',
                      icon: Icons.cloud_outlined,
                      color: NabuColors.violet),
                  ...providers.map((p) {
                    final selected = _selectedProvider == p.$1;
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      onTap: () {
                        // A model name only makes sense for its own provider:
                        // switching resets it to that provider's default.
                        if (!selected) _modelCtrl.clear();
                        ref.read(aiSettingsProvider.notifier).update(
                              AISettings(
                                provider: p.$1,
                                model: _modelCtrl.text.trim(),
                                baseUrl: _baseUrlCtrl.text.trim(),
                                useAI: ai.useAI,
                              ),
                            );
                        showSnack(context, 'Fournisseur : ${p.$2}');
                      },
                      child: Row(
                        children: [
                          Text(p.$3, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.$2,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(p.$4,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45)),
                              ],
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected ? NabuColors.violet : null,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  const SectionTitle(
                      title: 'Configuration',
                      icon: Icons.tune,
                      color: NabuColors.cyan),
                  if (isLLM)
                    TextField(
                      controller: _modelCtrl,
                      decoration: InputDecoration(
                        labelText: 'Modèle',
                        hintText: 'Laisser vide pour $defaultModel',
                      ),
                    )
                  else
                    TextField(
                      controller: _baseUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Adresse du serveur Ollama',
                        hintText: 'Ex : http://192.168.1.10:11434',
                      ),
                    ),
                  if (isLLM) ...[
                    for (final e in _keyCtrls.entries)
                      if (e.key == _selectedProvider) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: e.value,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Clé API ${providers.firstWhere((p) => p.$1 == e.key).$2}',
                            hintText: 'sk-...',
                          ),
                        ),
                      ],
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          label: 'Enregistrer',
                          icon: Icons.save_outlined,
                          onPressed: _assert,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.tonalIcon(
                        onPressed: _testing ? null : _test,
                        icon: _testing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.network_check),
                        label: const Text('Tester'),
                      ),
                    ],
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                            color: _testResult!.contains('réussie')
                                ? NabuColors.green
                                : const Color(0xFFFF5252)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Text(
                      '🔒 Ta clé API est chiffrée dans le stockage sécurisé de ton appareil. Elle n’est jamais envoyée ailleurs que vers ton fournisseur pour effectuer les requêtes.',
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}