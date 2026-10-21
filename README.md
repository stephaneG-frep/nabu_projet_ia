# NabuProjet IA — Votre chef de projet personnel, propulsé par l'IA

« Une idée, un sujet, un objectif. Léon, votre assistant IA, vous aide à discuter, planifier, exécuter et adapter vos projets personnels, du premier brainstorming jusqu'à la réussite finale. »

## Fonctionnalités

- **Idée → Projet** : décrivez votre idée, discutez avec Léon (IA), puis transformez-la en plan structuré en un clic.
- **Tableau de bord projet** : progression globale, objectifs clés, prochaine action, mise en œuvre, section rapide.
- **10 sections de gestion** : Objectifs, Tâches, Kanban, Planning, Budget, Ressources, Notes, Risques, Décisions, Journal.
- **Assistant IA multi-fournisseurs** : OpenAI, Mistral, Gemini, Claude, Ollama (clé API en stockage sécurisé).
  - « Que dois-je faire maintenant ? » — prochaine action générée par l'IA
  - « 🆘 Je suis bloqué » — déblocage pas à pas
  - « Adapter mon projet » — révision du plan
- **Mode 100 % hors ligne** : le « chef de projet » répond localement quand aucune clé IA n'est configurée (regroupement, priorisation, prochaine action basées sur l'état réel du projet).
- **Kanban par statut** (à faire / en cours / bloqué / terminé), filtres par priorité.
- **Planning** : jalons et échéances avec compte à rebours.
- **Budget** : suivi dépensé / prévu, avec notes.
- **Journal** : historique des événements du projet.
- **Export PDF** du rapport de projet (partage / impression).
- **Guide d'utilisation intégré** : 18 chapitres + 20 exemples d'utilisation + astuces.
- **Thèmes** sombre et clair, interface glassmorphism, animations fluides.
- **Aucune page vide, aucun bouton factice** : chaque écran agit sur des données réellement sauvegardées sur l'appareil.

## Installation sur Android

1. Copiez `NabuProjetIA_V1.0.0_Android_arm64.apk` sur votre téléphone (ARM 64 bits).
2. Ouvrez le fichier et autorisez l'installation depuis cette source si demandé.
3. Lancez « NabuProjet IA ».

## Compiler le projet soi-même

Prérequis : Flutter 3.44+ (Dart 3.12+), SDK Android (API 34+), JDK 17.

```bash
export PATH="/opt/flutter/bin:/opt/android-sdk/platform-tools:$PATH"
export ANDROID_HOME="/opt/android-sdk"
export ANDROID_SDK_ROOT="/opt/android-sdk"
cd nabu_projet_ia
flutter pub get
flutter analyze          # aucun problème attendu
flutter test             # tests unitaires + widget
flutter build apk --release --target-platform android-arm64
```

L'APK est généré dans `build/app/outputs/flutter-apk/app-release.apk`.

## Utiliser l'IA

1. Onglet **IA** → **Réglages IA** : choisissez votre fournisseur (OpenAI, Mistral, Gemini, Claude ou Ollama) et entrez votre clé API.
2. De retour à l'écran d'accueil, appuyez sur **« 💡 J'ai une idée »**.
3. Discutez avec Léon, puis **« Créer mon projet 🎉 »**.
4. Pilotez votre projet depuis **Projets** → votre projet → le tableau de bord (les actions IA sont en haut du tableau de bord).

Sans clé API, l'application fonctionne intégralement en mode hors ligne : les réponses et plans sont générés localement à partir de l'état réel de vos projets.

## Structure du code

```
lib/
  core/
    models/          Modèles de données (Projet, Tâche, Objectif, Décision, Risque…)
    services/        Persistance Hive, IA multi-fournisseurs, export PDF
    providers/       State management (Riverpod)
    theme/           Palette, thèmes sombre/clair
  widgets/           Composants réutilisables (GlassCard, GradientButton…)
  screens/
    onboarding/      Bienvenue / prise en main
    home/            Accueil (idées, projets, « Que dois-je faire maintenant ? »)
    projects/        Liste des projets, création idée→chat→plan, dashboard, chat
      sections/      Une section par fichier (objectifs, tâches, kanban, budget…)
    today/           Vue du jour (priorités, échéances)
    ai/              Hub IA, inspiration, réglages clés API
    profile/         Profil, préférences, réinitialisation
    help/            Guide d'utilisation (18 chapitres + exemples)
  main.dart          Point d'entrée
```

Version : 1.0.0