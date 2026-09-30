# Petit départ

PWA Flutter Web pour commencer une activité physique avec de très petites séances.
Le nom de l'application est provisoire.

## Voir l'application dans Codespaces

```bash
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8080 --bind 0.0.0.0 --directory build/web
```

Ouvrir ensuite le port 8080 dans l'onglet **Ports** de VS Code. La routine choisie
est enregistrée dans le navigateur. Le chronomètre et l'historique des séances
ne sont pas encore implémentés.

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

Le navigateur doit visiter le site une première fois en ligne pour installer
les fichiers nécessaires au mode hors connexion. Après cette visite, tester
l'installation et le démarrage hors connexion sur un téléphone compatible.

Voir [le guide complet](docs/GUIDE_PROJET_DE_A_A_Z.md) pour la suite du projet.
La [feuille de route](docs/PROCHAINES_ETAPES.md) indique l'étape suivante et les
critères de validation.
