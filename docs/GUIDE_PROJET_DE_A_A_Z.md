# Guide projet — PWA sportive « Petit départ »

> Document de travail pour débuter avec Flutter, Dart, GitHub Codespaces et Firebase Hosting.
> Le nom « Petit départ » est provisoire et peut être remplacé plus tard.

## 1. Objectif du produit

Cette application aide à commencer une activité physique avec un effort volontairement très court, puis à construire une habitude souple. Une séance de 10 secondes peut être une séance réussie. L’utilisateur choisit, adapte ou réduit son objectif.

L’application ne donne pas de prescription médicale et ne promet pas qu’une habitude apparaît après un nombre fixe de jours. Elle ne culpabilise pas, n’impose pas de rattrapage et considère le repos comme compatible avec la réussite.

### Version 1 (MVP)

La première version doit permettre de :

1. démarrer sans compte ;
2. choisir une routine courte lors du premier lancement ;
3. afficher la séance du jour ;
4. réaliser un exercice chronométré ou compté manuellement ;
5. mettre en pause, reprendre, arrêter ou passer un exercice ;
6. enregistrer uniquement ce qui a réellement été fait ;
7. consulter un historique simple ;
8. modifier la routine et l’objectif sans réécrire l’historique ;
9. installer la PWA sur un téléphone compatible.

La carte musculaire, la synchronisation cloud, les notifications et un catalogue étendu sont des évolutions, pas des prérequis du MVP.

## 2. Principes UX non négociables

- Une petite séance compte.
- Aucune progression automatique imposée.
- L’utilisateur peut augmenter, maintenir, réduire ou reporter.
- Une interruption ne déclenche ni reproche ni rattrapage obligatoire.
- Une reprise après plusieurs jours doit être aussi simple qu’un premier démarrage.
- Une journée de repos est visible et légitime.
- Les répétitions sont saisies ou validées manuellement ; l’application ne prétend pas les détecter automatiquement.
- Les durées actives sont séparées des pauses.
- Les calories, pourcentages d’activation musculaire et promesses de prévention des blessures sont exclus.

## 3. Parcours utilisateur

### Premier lancement

Écran 1 : expliquer en une phrase que l’on peut commencer petit.

Écran 2 : proposer quelques exercices aboutis, par exemple planche, squat et jumping jack sans saut.

Écran 3 : choisir une durée ou un nombre de répétitions adapté au mode de mesure.

Écran 4 : choisir les jours, avec « tous les jours » comme option mais pas comme obligation.

Écran 5 : confirmer et arriver sur « Aujourd’hui ».

Aucun compte, questionnaire de poids/taille ou test de performance n’est nécessaire.

### Écran Aujourd’hui

Afficher la routine prévue, les objectifs, une estimation de durée explicitement présentée comme une estimation, le bouton principal « Commencer », une action secondaire « Adapter la séance » et un encouragement court. Réduire les graphiques et réglages visibles simultanément.

### Séance

Pour chaque exercice : nom, illustration locale simple, consigne courte, objectif, boutons larges, pause/reprise/arrêt et option de passage. Un compte à rebours de préparation peut précéder un exercice chronométré. En cas d’arrêt, enregistrer la progression réelle et marquer la séance comme interrompue ou partielle, jamais comme entièrement terminée.

### Fin

Afficher une confirmation sobre, le travail réalisé et, facultativement, « Facile », « Bien dosé » ou « Difficile ». L’utilisateur peut quitter sans autre action obligatoire.

### Bilan

Après une période configurable, par défaut sept jours, proposer séparément pour chaque exercice : garder, augmenter légèrement, réduire ou reporter. Montrer la modification avant validation, par exemple `10 s → 15 s`. Le bilan ne réécrit jamais les séances passées.

## 4. Choix techniques

### Stack recommandée

- Dart et Flutter stable, avec la version indiquée par la documentation Flutter au moment de l’installation.
- Cible initiale : Web, rendu CanvasKit ou HTML selon les tests de performance et d’accessibilité.
- Architecture simple en couches : présentation, domaine, données.
- Gestion d’état : commencer avec `ChangeNotifier` ou une solution légère déjà maîtrisée ; ne pas multiplier les dépendances dans le MVP.
- Stockage local : une solution persistante compatible Web, choisie après un petit prototype. L’interface de données doit permettre de remplacer ce stockage plus tard.
- Tests : tests unitaires Dart, tests de widgets et tests d’intégration Web sur les parcours critiques.
- Déploiement : Firebase Hosting, avec HTTPS et domaine fourni par Firebase au début.
- Contrôle de version : GitHub, une branche principale protégée si le dépôt est partagé.

### Pourquoi une architecture en couches ?

Les écrans ne doivent pas calculer les statistiques ni écrire directement dans le stockage. Le domaine contient les règles : une séance partielle reste partielle, les pauses ne sont pas du temps actif et l’historique est immuable. Cette séparation rend le projet plus facile à tester et à faire évoluer.

### Ce qui reste local au MVP

Les préférences, routines et séances peuvent rester dans le navigateur. Il faut prévenir l’utilisateur qu’un effacement des données du navigateur peut supprimer ses données. Un compte et une synchronisation Firebase pourront être ajoutés ensuite avec une décision explicite sur la confidentialité.

## 5. Modèle de données initial

Les identifiants sont stables et ne dépendent pas du nom affiché.

```text
Exercise
  id, nameFr, category, measurementMode
  description, instructions, commonMistakes
  defaultTarget, defaultSets, defaultRestSeconds
  equipment, primaryMuscles, secondaryMuscles
  easierVariantId, harderVariantId, illustrationAsset
  safetyNotes, sourceIds

Routine
  id, name, exerciseSteps[], selectedWeekdays, createdAt, updatedAt

RoutineStep
  exerciseId, targetValue, sets, restSeconds, order

WorkoutSession
  id, routineId, startedAt, endedAt
  status (planned, completed, partial, stopped)
  activeSeconds, totalElapsedSeconds, feedback

WorkoutResult
  sessionId, exerciseId, completedSeconds, completedRepetitions
  skipped, variantId
```

Ne pas convertir automatiquement des répétitions en secondes ni mélanger temps actif et temps de pause. Les séances enregistrées ne sont pas modifiées lorsqu’une routine change.

## 6. Catalogue de départ

Commencer avec un petit catalogue réellement fini : planche, squat, pompe au mur, jumping jack sans saut, pont fessier, élévation de mollets et un mouvement de mobilité. Chaque fiche doit contenir la mesure pertinente : durée ou répétitions, et non toutes les unités à la fois.

Les variantes sont des options avec des exigences différentes, pas une échelle parfaite pour toutes les personnes. Les consignes doivent indiquer d’arrêter en cas de douleur inhabituelle et de demander un avis professionnel lorsque la situation le justifie.

Pour la course à pied, présenter les exercices complémentaires avec prudence : ils peuvent contribuer à travailler certaines capacités, mais ne garantissent pas l’absence de blessure et ne remplacent pas un programme individualisé. Renforcement, mobilité et étirements doivent être clairement distingués.

## 7. Direction artistique et accessibilité

Interface mobile-first, sombre uniquement dans la première version : fond anthracite, surfaces légèrement plus claires, texte blanc cassé et accent jaune. Utiliser une typographie lisible, des zones tactiles généreuses, une hiérarchie courte et des cartes arrondies avec modération.

Navigation principale : Aujourd’hui, Exercices, Progrès. Les paramètres restent accessibles depuis un menu ou une icône, sans devenir un quatrième espace principal.

Prévoir : contraste suffisant, libellés textuels pour les icônes, ordre de focus clavier, messages d’erreur compréhensibles, taille de texte adaptable, alternative textuelle à la carte du corps, et respect de la préférence système de réduction des animations.

La carte musculaire sera une évolution en SVG local : vue de face et de dos, zones sélectionnables, muscles principaux/secondaires et liste textuelle équivalente. Ne jamais afficher de pourcentages d’activation non sourcés.

## 8. Organisation du dépôt

```text
lib/
  main.dart
  app/
  features/
    onboarding/
    today/
    workout/
    exercises/
    progress/
  domain/
  data/
  design_system/
test/
  domain/
  widgets/
integration_test/
assets/
  illustrations/
  content/
docs/
  GUIDE_PROJET_DE_A_A_Z.md
  SOURCES_CONTENUS_SPORTIFS.md
web/
firebase.json
README.md
```

## 9. Installation dans GitHub Codespaces

### Préparer le dépôt

1. Créer un dépôt GitHub privé ou public.
2. Ouvrir un Codespace sur ce dépôt.
3. Vérifier que VS Code est connecté au bon dossier.
4. Installer ou activer l’extension Flutter/Dart.
5. Installer Flutter selon la documentation officielle et vérifier avec `flutter doctor`.

Ne pas copier aveuglément des versions trouvées dans d’anciens tutoriels : Flutter, Dart, Node et Firebase CLI évoluent.

### Créer le projet

Depuis la racine du dépôt, si aucun projet Flutter n’existe encore :

```bash
flutter create --platforms=web .
flutter pub get
flutter run -d chrome
```

Si le dépôt contient déjà des fichiers importants, faire un commit avant cette commande et vérifier le diff. Le nom de travail peut rester provisoire.

### Première vérification

```bash
flutter analyze
flutter test
flutter build web
```

Corriger les erreurs avant d’ajouter des fonctionnalités. La commande `flutter build web` vérifie que l’application est réellement compilable pour la cible PWA.

## 10. Plan de réalisation par étapes

### Étape A — socle et thème

Créer l’application, le thème sombre, la navigation et un écran Aujourd’hui statique. Ajouter un bouton « Commencer » qui ouvre un écran de séance simulé.

Critère : l’application démarre sur Web, les écrans sont navigables au clavier et aucun écran n’est vide sans explication.

### Étape B — onboarding

Créer le parcours court, enregistrer le choix local et rediriger vers Aujourd’hui. Permettre de modifier la sélection sans compte.

Critère : un nouvel utilisateur peut arriver à une routine active en moins de quelques écrans.

### Étape C — séance réelle

Implémenter chronomètre, compteur manuel, préparation, pause, reprise, arrêt, passage, variante et sauvegarde d’une séance partielle.

Critère : recharger la page après une séance et retrouver les données ; les pauses ne gonflent pas le temps actif.

### Étape D — routine et progression

Permettre d’ajouter, supprimer, réordonner et modifier les exercices. Ajouter le bilan configurable et la confirmation précise avant toute modification.

Critère : changer la routine ne change aucune séance de l’historique.

### Étape E — progrès et contenu

Afficher séances de la semaine, temps actif, répétitions, jours actifs, historique et petits jalons. Ajouter les fiches d’exercices et les sources.

Critère : les métriques restent séparées et aucune récompense ne pousse à ignorer le repos.

### Étape F — PWA et déploiement

Configurer le manifeste Web, les icônes, un service worker propre au projet, le mode responsive et Firebase Hosting. Les versions récentes de Flutter ne génèrent plus de cache hors connexion utilisable par défaut. Tester installation, rafraîchissement direct d’une route et comportement hors connexion prévu.

Critère : un téléphone peut ouvrir et installer l’application ; les routes essentielles ne renvoient pas une erreur après rafraîchissement.

## 11. Firebase Hosting

Installer Firebase CLI selon la documentation Firebase, se connecter avec le bon compte puis, depuis le projet :

```bash
firebase login --no-localhost
firebase projects:list
flutter build web --release --no-web-resources-cdn
firebase deploy --only hosting --project IDENTIFIANT_DU_PROJET
```

La configuration Hosting est déjà présente dans `firebase.json` : le dossier public est `build/web` et les routes inconnues reviennent vers `index.html`. Il n'est donc pas nécessaire de relancer `firebase init hosting`, qui pourrait modifier cette configuration. Remplacer `IDENTIFIANT_DU_PROJET` par l'identifiant exact affiché par `firebase projects:list`.

La commande `--no-web-resources-cdn` inclut localement les ressources de rendu nécessaires au démarrage hors connexion. Le service worker du projet met en cache les fichiers essentiels après la première visite en ligne ; le mode hors connexion a été testé dans un navigateur automatisé, et reste à confirmer sur un téléphone réel. Les changements sont récupérés en priorité sur le réseau lors des visites suivantes.

Ne jamais publier une clé privée, un jeton de connexion ou un fichier `.env` contenant des secrets. Les changements de production doivent être précédés d’une vérification locale et d’un commit identifiable.

## 12. Sources et prudence des contenus

Créer `docs/SOURCES_CONTENUS_SPORTIFS.md` dès que des affirmations sportives sont ajoutées. Pour chaque conseil, noter la source, sa date de consultation, la phrase soutenue et les limites d’interprétation. Utiliser de préférence des organismes de santé publique, des recommandations professionnelles et des articles scientifiques accessibles.

Un contenu non vérifié doit être marqué comme tel ou retiré. Éviter les formulations absolues : « peut contribuer à », « selon la capacité de la personne » et « ne remplace pas un avis professionnel » sont souvent plus honnêtes que des promesses.

## 13. Tests et checklist avant livraison

### Tests fonctionnels

- Premier lancement sans compte.
- Choix d’une routine et d’un jour de repos.
- Démarrage, pause, reprise et arrêt.
- Validation manuelle de répétitions.
- Séance partielle enregistrée correctement.
- Rechargement de la page sans perte inattendue.
- Modification d’une routine sans modification de l’historique.
- Bilan avec garder, augmenter, réduire et reporter.
- Navigation clavier et lecteur d’écran sur les écrans principaux.
- Installation et lancement depuis l’écran d’accueil mobile.

### Qualité technique

```bash
dart format .
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
```

Tester au moins un petit écran mobile, un écran large, une connexion lente et la préférence de réduction des animations. Vérifier les journaux sans laisser de données personnelles dans la console.

## 14. Évolutions après le MVP

Ordre conseillé : carte musculaire SVG et liste accessible, notifications facultatives, export/suppression des données, synchronisation avec compte explicite, davantage d’exercices, puis éventuel backend. Ne pas ajouter de compte, classement ou gamification agressive avant d’avoir validé le parcours de démarrage.

## 15. Règle de collaboration avec Codex

Avant chaque étape, annoncer :

1. le modèle GPT choisi dans le sélecteur ;
2. le niveau de raisonnement si disponible ;
3. l’objectif de l’étape ;
4. les fichiers qui seront modifiés ;
5. la vérification prévue.

Pour les décisions d’architecture, les gros changements multi-fichiers et les revues de sécurité : modèle de raisonnement avancé, généralement `High` ou `Pro` selon ce qui est proposé dans l’interface. Pour une petite correction locale ou une mise en forme : modèle rapide/Instant peut suffire. Si un nom de modèle n’est pas visible dans ton sélecteur, choisir l’équivalent le plus puissant disponible et le signaler.

## 16. Définition de terminé pour la première version

La V1 est terminée lorsque l’utilisateur peut ouvrir la PWA, comprendre le concept, choisir une petite routine, réaliser une séance chronométrée ou comptée, arrêter sans être culpabilisé, retrouver son historique, adapter sa progression et installer l’application sur mobile. Les tests critiques passent et les contenus sportifs sont séparés des affirmations non vérifiées.
