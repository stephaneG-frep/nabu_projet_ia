import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared.dart';
import '../projects/project_create_flow.dart';

class InspirationScreen extends StatelessWidget {
  const InspirationScreen({super.key});

  static const _ideas = [
    ('🎓', 'Apprendre quelque chose', 'Se lancer dans l\'apprentissage d\'une nouvelle compétence.',
        ['J\'apprends le piano', 'J\'apprends la photographie', 'Je me remets aux mathématiques', 'J\'apprends l\'espagnol', 'Je découvre la permaculture']),
    ('🎨', 'Créer quelque chose', 'Créer une œuvre, un objet ou un contenu.',
        ['Je crée une BD', 'Je fabrique une lampe en bois', 'J\'écris un roman court', 'Je crée mon podcast', 'Je dessine une série de cartes']),
    ('🌿', 'Améliorer mon quotidien', 'Réorganiser sa vie et son espace.',
        ['Je range ma maison (méthode)', 'Je crée une routine matinale', 'Je réorganise mon entraînement', 'Je me lance dans le zéro déchet', 'Je prépare mes repas à l\'avance']),
    ('💻', 'Projet informatique', 'Coder une application, un site ou un objet connecté.',
        ['Je crée une app de suivi de lectures', 'Je fabrique une station météo maison', 'Je crée un site pour une association', 'Je programme un jeu vidéo simple', 'Je monte un NAS personnel']),
    ('🏡', 'Projet maison', 'Améliorer, réparer, rénover.',
        ['Je restaure un meuble', 'Je repeins ma chambre', 'Je rénove ma salle de bain', 'Je crée un atelier de bricolage', 'J\'isole mes combles']),
    ('✈️', 'Projet voyage', 'Organiser un voyage mémorable.',
        ['Je voyage seul au Japon', 'Je fais le tour de l\'Europe en train', 'Je fais un trek dans les Pyrénées', 'J\'organise un road-trip familial', 'Je pars 3 mois en Asie']),
    ('🚀', 'Projet professionnel', 'Développer sa carrière ou se reconvertir.',
        ['Je crée ma micro-entreprise', 'Je change de métier', 'Je relance mon portfolio', 'Je lance ma chaîne YouTube pro', 'Je démarre le freelancing']),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              title: const Text('✨ Inspiration'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Je veux faire quelque chose mais je manque d\'idées',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color:
                                isDark ? Colors.white : const Color(0xFF1A1233),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choisis un thème ou laisse l\'IA te surprendre.',
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.black.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 14),
                        GradientButton(
                          label: '✨ Surprends-moi',
                          icon: Icons.casino_outlined,
                          expanded: true,
                          onPressed: () {
                            final idx = DateTime.now().millisecondsSinceEpoch % _ideas.length;
                            final cat = _ideas[idx];
                            final idea = cat.$4[DateTime.now().microsecondsSinceEpoch % cat.$4.length];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ProjectCreateFlowScreen(initialIdea: idea)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._ideas.map((idea) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          onTap: () => _showIdeasSheet(context, isDark, idea),
                          child: Row(
                            children: [
                              Text(idea.$1, style: const TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(idea.$2,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    Text(
                                      idea.$3,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black45),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  size: 22,
                                  color: isDark ? Colors.white38 : Colors.black26),
                            ],
                          ),
                        ),
                      )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIdeasSheet(
      BuildContext context, bool isDark, (String, String, String, List<String>) category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1840) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(category.$1, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.$2,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: isDark ? Colors.white : const Color(0xFF1A1233))),
                        Text(category.$3,
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black45)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: category.$4
                      .map((idea) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              tileColor: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              leading: Text(category.$1,
                                  style: const TextStyle(fontSize: 20)),
                              title: Text(idea,
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w600)),
                              trailing: const Icon(Icons.auto_awesome,
                                  size: 18, color: NabuColors.violet),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ProjectCreateFlowScreen(
                                          initialIdea: idea)),
                                );
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
