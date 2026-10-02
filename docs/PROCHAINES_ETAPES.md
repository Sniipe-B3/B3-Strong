# Prochaines étapes — Petit départ

Mise à jour : 2 octobre 2026. Ce fichier suit l'avancement concret du projet.
Le cahier des charges détaillé se trouve dans [le guide de A à Z](GUIDE_PROJET_DE_A_A_Z.md).

## Où en est-on ?

La PWA Flutter Web est publiée sur <https://b3-strong.web.app>. Elle possède le
thème sombre anthracite et jaune, une navigation à trois onglets, un manifeste,
des icônes, un service worker et un hébergement HTTPS sur Firebase. L'accueil a
été testé en ligne et hors connexion dans un navigateur automatisé. L'installation
sur un téléphone réel reste à vérifier.

Les nouvelles versions publiées sont maintenant détectées par la PWA : le
service worker reçoit un identifiant de build différent lorsque les fichiers
changent, puis un onglet ouvert recharge la nouvelle version. Le passage d'une
version à l'autre et le démarrage hors connexion ont été vérifiés dans un
navigateur automatisé. Un ancien onglet ouvert avant cette amélioration peut
demander un dernier rafraîchissement.

Le premier lancement permet de choisir une petite routine, ses objectifs et ses
jours, conservés localement dans le navigateur. « Aujourd'hui » reconnaît les
jours de repos. Une vraie séance chronométrée ou comptée manuellement peut être
mise en pause, reprise, passée ou arrêtée. Les résultats, y compris partiels,
sont sauvegardés localement ; le dernier apparaît sur « Aujourd'hui » après un
rechargement. Une séance interrompue par le navigateur revient en pause, sans
compter le temps passé hors de l'application. Une mise à jour de la PWA attend
la fin d'une séance avant de proposer l'actualisation. L'onglet Exercices reste
un écran d'attente.
La routine peut maintenant être modifiée exercice par exercice, avec séries,
repos et jours, après un aperçu avant confirmation. Les anciennes séances
gardent les objectifs qui étaient en vigueur au moment où elles ont commencé.
L'onglet Progrès affiche les séances de la semaine, les jours réellement actifs,
les durées et répétitions séparées, l'historique et de petits jalons sans série
de jours à préserver.
Un bilan facultatif apparaît après une période choisie de 7, 14 ou 28 jours
(sept par défaut) à partir d'une séance enregistrée. Chaque exercice peut être
gardé, légèrement augmenté, réduit ou reporté indépendamment. Un aperçu montre
les valeurs avant et après ; seule la prochaine routine change après confirmation.
Le rythme et la date du dernier bilan restent dans le navigateur, sans compte.

## Ordre de travail

### 1. Premier lancement et routine personnelle

**Statut : terminé et vérifié dans un navigateur.**

**Modèle conseillé : GPT-6.1 Sol, niveau Medium** (ou le modèle de codage
récent disponible avec un niveau de raisonnement équivalent).

- Expliquer le concept en une phrase et proposer quelques exercices simples.
- Faire choisir un objectif adapté à chaque exercice : secondes ou répétitions.
- Faire choisir les jours souhaités, avec une option quotidienne.
- Enregistrer la routine dans un stockage local compatible Web et ouvrir
  directement « Aujourd'hui » aux visites suivantes.
- Permettre de revoir ses choix, sans compte obligatoire.

**Terminé quand :** un nouvel utilisateur peut configurer une petite routine,
rafraîchir la page et retrouver exactement ses choix. Un jour de repos est
clairement indiqué et permet toujours une séance volontaire.

### 2. Vraie séance et enregistrement fidèle

**Statut : terminé et vérifié par tests ; déployé sur Firebase Hosting.**

**Modèle conseillé : GPT-6.1 Sol, niveau High**, car le chronomètre, les pauses
et la reprise demandent des règles précises.

- Ajouter un délai de préparation avant les exercices chronométrés.
- Ajouter pause, reprise, arrêt, passage et variante plus facile.
- Faire valider manuellement les répétitions.
- Enregistrer le temps actif, les répétitions et la durée totale séparément.
- Conserver une séance interrompue comme partielle, avec le travail réellement
  effectué. Proposer un bilan facultatif à la fin.
- Suspendre le rechargement automatique d'une mise à jour pendant une séance
  active, puis proposer l'actualisation une fois les données sauvegardées.

**Terminé quand :** les résultats restent exacts après pause, arrêt et
rafraîchissement. Aucune répétition n'est comptée automatiquement et une séance
partielle n'est jamais affichée comme terminée.

### 3. Modifier sa routine

**Statut : terminé et vérifié par tests ; déployé sur Firebase Hosting.**

**Modèle conseillé : GPT-6.1 Sol, niveau Medium.**

- Ajouter, retirer et réordonner les exercices.
- Modifier objectifs, séries et repos lorsque c'est pertinent.
- Afficher la modification avant de l'enregistrer.
- Conserver dans l'historique les objectifs d'origine de chaque séance.

**Terminé quand :** une modification de routine apparaît dans la prochaine
séance, sans modifier les séances déjà enregistrées.

### 4. Progrès simples et reprise sereine

**Statut : terminé et vérifié par tests ; déployé sur Firebase Hosting.**

**Modèle conseillé : GPT-6.1 Sol, niveau Medium.**

- Afficher les séances de la semaine, les jours actifs et l'historique.
- Afficher séparément secondes actives, durée totale et répétitions.
- Accueillir positivement une reprise après une interruption.
- Ajouter de petits jalons sans classement, perte de points ou pression de série.

**Terminé quand :** tous les chiffres correspondent aux séances enregistrées ;
le repos et les interruptions ne provoquent aucun message culpabilisant.

### 5. Bilan et progression choisie

**Statut : terminé et vérifié par tests ; déployé sur Firebase Hosting.**

**Modèle conseillé : GPT-6.1 Sol, niveau High.**

- Après une période configurable, proposer pour chaque exercice : garder,
  augmenter, réduire ou reporter.
- Montrer la valeur avant et après, par exemple `10 s → 15 s`.
- Ne jamais augmenter automatiquement ni réécrire l'historique.

**Terminé quand :** les quatre choix fonctionnent indépendamment pour chaque
exercice et reporter laisse le programme inchangé.

### 6. Catalogue et qualité des contenus

**Modèle conseillé : GPT-6.1 Sol, niveau High** pour la vérification des sources.

- Compléter un petit catalogue : planche, squats, pompes adaptées, jumping jack
  sans saut, pont fessier, mollets et quelques mouvements de mobilité.
- Ajouter consignes courtes, variantes, précautions et illustrations locales.
- Créer `docs/SOURCES_CONTENUS_SPORTIFS.md` avec les sources vérifiées.
- Distinguer renforcement, mobilité et étirements. Ajouter ensuite les contenus
  complémentaires à la course à pied avec des formulations prudentes.

**Terminé quand :** chaque conseil sportif affiché est vérifié ou clairement
signalé comme non vérifié ; les fiches sont compréhensibles sur mobile.

### 7. Vérification de la PWA sur appareils réels

**Modèle conseillé : GPT-6.1 Sol, niveau Medium.**

- Ouvrir le site sur Android et, si disponible, sur iPhone.
- Tester « Ajouter à l'écran d'accueil », le lancement installé, la reconnexion
  et un démarrage hors connexion après une première visite en ligne.
- Tester un petit écran, le clavier, les libellés accessibles, les grandes tailles
  de texte et la réduction des animations.
- Vérifier le comportement du navigateur du MacBook Air 2013 sans faire dépendre
  la compilation du Mac : le build reste dans Codespaces.

**Terminé quand :** les principaux parcours restent utilisables sur les appareils
visés et les limites éventuelles sont documentées.

## Après le MVP

Carte musculaire SVG avec liste textuelle équivalente, export et suppression des
données, notifications facultatives, puis éventuel compte et synchronisation.
La synchronisation n'est pas nécessaire au fonctionnement actuel de Firebase
Hosting : l'hébergement du site et le stockage des données utilisateur sont
deux sujets distincts.

## Règle de travail pour chaque étape

1. Annoncer le modèle GPT à choisir **avant** de commencer et celui de l'étape
   suivante **à la fin**. La [documentation officielle OpenAI sur le choix du
   modèle](https://developers.openai.com/api/docs/guides/model-selection)
   donne une base ; les noms visibles dépendent du compte.
2. Modifier les fichiers nécessaires, puis vérifier au minimum `flutter analyze`
   et `flutter test`. Pour une étape Web, compiler avec
   `flutter build web --release --no-web-resources-cdn`.
3. Tester le parcours concerné, puis déployer sur Firebase Hosting lorsque la
   version est prête à être montrée. Le hook `predeploy` versionne le service
   worker à partir du build ; ne jamais déployer sans recompiler les nouveautés.
4. Faire un **commit Git et un push sur GitHub** après l'étape terminée. Ne pas
   ajouter `build/`, `.dart_tool/`, `.firebase/`, journaux ou secrets au dépôt.
5. Mettre ce fichier à jour pour marquer l'étape achevée et indiquer la suivante.

La prochaine étape de développement est **6. Catalogue et qualité des contenus**.
