import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final _chapters = <(String, IconData, Color, String)>[
    ('1. Bienvenue dans NabuProjet IA', Icons.waving_hand_outlined, NabuColors.violet,
        'NabuProjet IA est ton chef de projet personnel propulsé par l’IA. Tu donnes une idée simple (« je veux apprendre Python », « je veux refaire mon jardin »...) et l’application la transforme en projet structuré : objectifs, étapes, tâches, planning, budget, risques. Grâce à la sauvegarde locale automatique, tout reste sur ton appareil, même sans connexion.'),
    ('2. Créer son premier projet', Icons.add_box_outlined, NabuColors.electricBlue,
        'Va sur l’onglet Accueil et tape dans la zone « Décris ton idée... ». Appuie ensuite sur « ✨ Transformer mon idée en projet ». L’assistant discute avec toi, pose quelques questions, puis génère un plan complet. Tu peux aussi créer un projet sans IA : un plan de base sera proposé et personnalisable.'),
    ('3. Transformer une idée en projet', Icons.auto_awesome, NabuColors.magenta,
        'Dans la conversation de création, réponds naturellement aux questions (objectif, niveau, budget, temps disponible, échéance). Après quelques échanges, le bouton « Créer mon projet » apparaît. L’IA génère : nom, description, objectifs, tâches avec priorités et durées, risques, budget estimé et prochaine action.'),
    ('4. Comprendre le dashboard', Icons.dashboard_outlined, NabuColors.cyan,
        'Chaque projet a une page principale avec : la progression globale, la « prochaine meilleure action », et des cartes d’accès : Objectif, Tâches, Planning, Budget, Ressources, Notes, Risques, Décisions, Journal, Assistant IA et Rapport PDF. Touche une carte pour ouvrir la section concernée.'),
    ('5. Créer des tâches', Icons.checklist, NabuColors.electricBlue,
        'Ouvre la section Tâches du projet puis « Nouvelle tâche ». Renseigne le titre, la priorité, la durée estimée, la date d’échéance et d’éventuelles sous-tâches. Coche une tâche pour la terminer : la progression globale se met à jour automatiquement.'),
    ('6. Utiliser le Kanban', Icons.view_kanban_outlined, NabuColors.violet,
        'La vue Kanban organise les tâches en 4 colonnes : À faire, En cours, Bloqué, Terminé. Glisse simplement une carte de tâche d’une colonne à l’autre pour changer son statut.'),
    ('7. Utiliser le planning', Icons.calendar_month, NabuColors.cyan,
        'La section Planning regroupe les tâches par période : Aujourd’hui, Cette semaine, Plus tard. Elle affiche aussi la timeline du projet (IDÉE → PRÉPARATION → PROTOTYPE → TEST → AMÉLIORATION → FINALISATION) avec ta position actuelle.'),
    ('8. Discuter avec le chef de projet IA', Icons.forum_outlined, NabuColors.magenta,
        'Chaque projet possède son propre assistant. Ouvre « 💬 Chef de projet » depuis le dashboard. Il connaît ton projet (tâches, progression, notes, risques) et répond avec ce contexte. Utilise les suggestions rapides : « Que dois-je faire maintenant ? », « Je suis bloqué », « Adapte mon planning ».'),
    ('9. Utiliser « Que dois-je faire maintenant ? »', Icons.bolt, NabuColors.violet,
        'Depuis le dashboard, appuie sur « Que dois-je faire maintenant ? ». L’IA analyse la progression, les priorités et les dépendances, puis recommande UNE action avec une durée estimée. Lance-toi !'),
    ('10. Que faire lorsqu’on est bloqué', Icons.healing_outlined, NabuColors.orange,
        'Utilise « 🆘 Je suis bloqué » : décris ton problème et l’IA propose une solution rapide, une solution recommandée et une alternative, avec des explications sur l’impact pour le projet. Tu peux enregistrer le blocage dans le journal.'),
    ('11. Adapter un projet', Icons.sync_alt, NabuColors.cyan,
        'Le projet n’est jamais figé. Dans la section « Adapter mon projet », explique ta nouvelle contrainte (« j’ai seulement 5 jours », « cette tâche a pris deux fois plus de temps »). L’IA propose une réorganisation concrète du planning et des priorités.'),
    ('12. Gérer son budget', Icons.payments_outlined, NabuColors.turquoise,
        'La section Budget affiche le budget prévu, les dépenses et le reste disponible, par catégorie (matériel, logiciel, déplacement, services, autres). Ajoute des mouvements en précisant s’il s’agit d’une prévision ou d’une dépense.'),
    ('13. Utiliser les notes', Icons.sticky_note_2_outlined, NabuColors.orange,
        'Le bloc-notes du projet permet de capturer idées, problèmes, décisions, informations et réflexions. Chaque note est datée et triée par type.'),
    ('14. Prendre une décision avec l’IA', Icons.balance_outlined, NabuColors.deepViolet,
        'Dans l’espace Décisions, enregistre une question avec ses options (« Flutter ou React Native ? »). L’IA présente les POUR, CONTRE, RISQUES, IMPACT et une RECOMMANDATION. La décision finale t’appartient toujours.'),
    ('15. Faire un bilan', Icons.insights_outlined, NabuColors.green,
        'Demande à l’assistant IA « Fais le point » : il résume ce qui avance bien, ce qui prend du retard, les difficultés, les risques, la prochaine priorité et une recommandation.'),
    ('16. Exporter un projet en PDF', Icons.picture_as_pdf_outlined, NabuColors.red,
        'Depuis le dashboard, ouvre le menu ⋮ puis « Rapport PDF ». Un PDF propre est généré : objectifs, progression, tâches terminées/restantes, planning, budget, décisions, risques, journal et bilan. Tu peux ensuite le partager.'),
    ('17. Configurer son fournisseur IA', Icons.cloud_outlined, NabuColors.violet,
        'Onglet Profil → « Fournisseur IA ». Choisis OpenAI, Gemini, Mistral, Claude ou Ollama, entre ta clé API (chiffrée dans le stockage sécurisé de l’appareil), indique le modèle si besoin (laisser vide = modèle par défaut), puis utilise « Tester » pour vérifier la connexion. Sans configuration, l’app fonctionne en mode hors ligne.'),
    ('18. Sauvegarde des projets', Icons.shield_outlined, NabuColors.green,
        'Tous les projets, tâches, objectifs, conversations, notes, budget, risques et préférences sont enregistrés automatiquement sur ton appareil (Hive / SQLite). Tu peux fermer l’application et la rouvrir : rien ne se perd.'),
  ];

  final _examples = [
    ('💻', 'Apprendre Python en 3 mois', '🎓 Apprentissage'),
    ('📱', 'Créer une application mobile de suivi de lectures', '💻 Informatique'),
    ('🌱', 'Créer un potager sur son balcon', '🌱 Jardin'),
    ('🏡', 'Restaurer une commode ancienne', '🔨 Bricolage'),
    ('🚀', 'Lancer sa micro-entreprise de création de sites', '🚀 Entreprise'),
    ('✈️', 'Organiser un voyage sac à dos au Japon', '✈️ Voyage'),
    ('🎨', 'Écrire et illustrer un livre pour enfants', '🎨 Créatif'),
    ('🎓', 'Apprendre l’espagnol avant un voyage', '🎓 Apprentissage'),
    ('💻', 'Construire une station météo connectée', '💻 Informatique'),
    ('🏡', 'Réorganiser le garage', '🏡 Maison'),
    ('❤️', 'Courir son premier semi-marathon', '❤️ Personnel'),
    ('💼', 'Préparer sa reconversion professionnelle', '💼 Professionnel'),
    ('🎨', 'Dessiner et imprimer des cartes de vœux', '🎨 Créatif'),
    ('💻', 'Créer un site vitrine pour une association', '💻 Informatique'),
    ('🌱', 'Aménager un espace détente dans le jardin', '🌱 Jardin'),
    ('🎓', 'Apprendre à jouer du piano', '🎓 Apprentissage'),
    ('🚀', 'Lancer un podcast thématique', '🚀 Entreprise'),
    ('✈️', 'Faire un road-trip en van en Europe', '✈️ Voyage'),
    ('🏡', 'Isoler et refroidir un local professionnel', '🔨 Bricolage'),
    ('❤️', 'Réserver, meubler et s’installer dans un studio', '🏡 Maison'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          isDark: isDark,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        const Text('📖 Mode d’emploi',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TabBar(
                      tabs: const [
                        Tab(text: 'Chapitres'),
                        Tab(text: 'Exemples'),
                        Tab(text: 'Astuces'),
                      ],
                      indicatorColor: NabuColors.violet,
                      labelColor: NabuColors.violet,
                      unselectedLabelColor: isDark
                          ? Colors.white54
                          : Colors.black45,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: _chapters
                          .map((c) => GlassCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: c.$3.withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(c.$2,
                                              color: c.$3, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            c.$1,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      c.$4,
                                      style: TextStyle(
                                          fontSize: 13,
                                          height: 1.45,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const SectionTitle(
                            title: '20 exemples de projets',
                            icon: Icons.emoji_objects_outlined,
                            color: NabuColors.orange),
                        ..._examples.map((e) => GlassCard(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Text(e.$1,
                                      style:
                                          const TextStyle(fontSize: 26)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(e.$2,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14)),
                                        Text(e.$3,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.black45)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                    ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const SectionTitle(
                            title: 'Astuces',
                            icon: Icons.lightbulb_outline,
                            color: NabuColors.cyan),
                        ...[
                          ('💡', 'Commence petit',
                              'Découpe toujours ton projet en très petites actions de 15-30 minutes. La régularité bat l’intensité.'),
                          ('📅', 'Donne des dates réalistes',
                              'Si tu ne sais pas, prends 2 fois plus de temps que ton intuition et réduis après coup.'),
                          ('🧠', 'Explique-toi simplement',
                              'Tu n’as pas besoin de vocabulaire technique : écris naturellement, l’IA comprend.'),
                          ('🆘', 'Bloqué ? Préviens l’IA',
                              'Plus tôt tu signales un blocage, plus tôt le plan est adapté.'),
                          ('🔐', 'Tes données restent à toi',
                              'Tout est sauvegardé localement. Le projet ne dépend pas d’Internet.'),
                          ('⚖️', 'Les décisions t’appartiennent',
                              'L’IA recommande, tu décides. Chaque décision importante se garde dans l’historique.'),
                          ('🎯', 'Une action à la fois',
                              'La question magique : « Que dois-je faire maintenant ? ». Réponds-y et fais-le.'),
                          ('📈', 'Fais des bilans',
                              'Une fois par semaine, demande un bilan IA pour recaler la trajectoire.'),
                          ('🖌️', 'Personnalise',
                              'Renomme, change les priorités, ajoute des sous-tâches : le plan est à toi.'),
                        ].map((a) => GlassCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(a.$1,
                                      style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(a.$2,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text(a.$3,
                                            style: TextStyle(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black54)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 20),
                        GradientButton(
                          label: 'Commencer un projet',
                          icon: Icons.rocket_launch_outlined,
                          expanded: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}