# Petit départ

PWA Flutter Web pour commencer une activité physique avec de très petites séances.
Le nom de l'application est provisoire.

## Voir l'application dans Codespaces

```bash
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8080 --bind 0.0.0.0 --directory build/web
```

Ouvrir ensuite le port 8080 dans l'onglet **Ports** de VS Code. La routine choisie
est enregistrée dans le navigateur. Une vraie séance propose préparation,
chronomètre ou compteur manuel, pause, reprise, passage et arrêt. Une séance
interrompue reste partielle. Le dernier résultat est visible sur « Aujourd’hui ».
L'onglet « Progrès » présente la semaine en cours, les jours actifs, les temps
et répétitions séparés, ainsi que l'historique détaillé des séances.
Le bouton « Adapter la séance » permet d'ajouter, retirer et réordonner les
exercices, d'ajuster objectifs, séries, repos et jours, puis de vérifier les
changements avant de les enregistrer. Les anciennes séances gardent leurs
objectifs d'origine.

## Publier sur Firebase Hosting

Un projet Firebase doit d'abord exister dans la console Firebase. Dans le
terminal du Codespace, se connecter avec son compte Google :

```bash
firebase login --no-localhost
firebase projects:list
```

La première commande affiche un lien d'authentification. Ouvrir ce lien dans
son navigateur et terminer la connexion dans le terminal. Ne pas copier de code
d'authentification dans un fichier du dépôt.

Le projet de ce dépôt est **B3-Strong** (`b3-strong`). Pour une future mise à jour :

```bash
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn
firebase deploy --only hosting --project b3-strong
```

La configuration [firebase.json](firebase.json) sert le dossier `build/web` et
renvoie les routes inconnues vers `index.html`. Le site est accessible à
https://b3-strong.web.app après le déploiement.

Le déploiement lance automatiquement `scripts/prepare_hosting.mjs` : il donne
au service worker un identifiant calculé à partir des fichiers du build. Quand
une nouvelle version est détectée, un onglet déjà ouvert se recharge tout seul
(immédiatement ou à son retour au premier plan). Il faut donc **compiler avant
chaque déploiement**. Si le build est absent, le déploiement est annulé. La
routine enregistrée dans le navigateur n'est pas effacée par cette mise à jour.
Une mise à jour détectée pendant une séance attend sa fin et propose un bouton
d'actualisation, pour ne pas interrompre l'exercice.
Un onglet ouvert avant l'installation de ce mécanisme peut nécessiter un dernier
rafraîchissement normal pour en bénéficier.

Les données de routine et de séance sont locales au navigateur, pas synchronisées
par Firebase Hosting. Effacer les données du site les supprimera. Le temps actif
exclut préparation et pauses ; la durée totale comprend le temps passé sur la
séance quand elle est ouverte, pauses comprises, mais pas la période où le site
est fermé. Les statistiques de semaine utilisent le jour local de fin de séance,
du lundi au dimanche. Une séance interrompue sans effort reste dans l'historique
mais ne compte pas comme jour actif.

Le navigateur doit visiter le site une première fois en ligne pour installer
les fichiers nécessaires au mode hors connexion. Après cette visite, tester
l'installation et le démarrage hors connexion sur un téléphone compatible.

Voir [le guide complet](docs/GUIDE_PROJET_DE_A_A_Z.md) pour la suite du projet.
La [feuille de route](docs/PROCHAINES_ETAPES.md) indique l'étape suivante et les
critères de validation.
