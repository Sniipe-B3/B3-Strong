# Test de la PWA sur tes appareils

État au 2 octobre 2026 : **à confirmer sur des appareils réels**. Depuis
Codespaces, un navigateur Chromium automatisé a ouvert la version publiée en
390 × 844 pixels, lu le manifeste, confirmé le service worker, puis rechargé
l'application hors connexion. Cela ne remplace pas les essais sur ton téléphone
ou ton Mac.

Adresse à tester : <https://b3-strong.web.app>

## Sur ton téléphone principal

1. Ouvre l'adresse ci-dessus **en ligne** et attends de voir « Bienvenue » ou
   « Aujourd'hui ». Ouvre une fiche dans **Exercices** ; regarde si la
   démonstration bouge, puis essaie **Mettre en pause** et **Reprendre**.
2. Installe depuis le navigateur : sur **Android/Chrome**, menu ⋮ →
   **Ajouter à l'écran d'accueil** → **Installer** si proposé. Sur
   **iPhone/Safari**, **Partager** → **Sur l'écran d'accueil** → **Ajouter**.
3. Lance l'icône installée. Vérifie qu'elle ouvre Petit départ, sans page
   blanche. Crée une toute petite routine si ce n'est pas déjà fait, puis
   ferme et rouvre l'application : elle doit retrouver tes choix.
4. Après cette visite en ligne, coupe Wi‑Fi **et** données mobiles, ferme
   l'application, puis ouvre-la à nouveau depuis l'icône. L'accueil, les
   fiches d'exercices et tes données locales doivent rester accessibles.
   Rétablis ensuite la connexion et vérifie que le site fonctionne toujours.
5. Essaie une courte séance, la pause et la reprise. Ne supprime pas les
   données du navigateur pour ce test : elles contiennent ta routine.

## Confort et accessibilité

- Vérifie en portrait sur un petit écran : boutons et textes doivent rester
  visibles sans débordement. Essaie aussi le mode paysage si tu l'utilises.
- Augmente la taille du texte dans les réglages du téléphone : les consignes
  doivent rester lisibles et les boutons accessibles.
- Active **Réduire les animations** dans les réglages d'accessibilité, puis
  retourne dans une fiche d'exercice : elle doit montrer une image fixe et le
  message « Animation désactivée ».
- Si tu utilises VoiceOver ou TalkBack, vérifie que les boutons essentiels
  (navigation, séance, pause/reprise) sont annoncés clairement.

## Sur le MacBook Air 2013

Ouvre simplement le site dans ton navigateur habituel. Note la version de
**macOS** et du **navigateur** (menu Safari → À propos de Safari, ou menu du
navigateur → À propos), puis essaie l'accueil, une fiche animée et une courte
séance. Le build reste dans Codespaces : aucune installation de Flutter n'est
nécessaire sur le Mac. La fonction Safari **Ajouter au Dock** demande macOS
Sonoma 14 ou plus récent ; si elle n'existe pas sur ton Mac, utilise un favori
du navigateur. Les versions récentes de Flutter ciblent Safari 15.6 et plus
récent pour le Web : sur un navigateur plus ancien, note tout écran blanc ou
comportement étrange sans supposer que l'application fonctionnera.

## Résultats à me transmettre

Pour chaque appareil essayé, indique : appareil + version du système et du
navigateur ; installation **oui/non** ; ouverture hors connexion **oui/non** ;
animation et pause **oui/non** ; problème éventuel (capture d'écran si possible).
Ne transmets pas de données personnelles ou de code de connexion.

## Contrôle automatisé reproductible

Dans Codespaces, après un déploiement, le contrôle du navigateur peut être
relancé avec :

```bash
CHROME_BIN=/chemin/vers/chromium node scripts/smoke_pwa.mjs https://b3-strong.web.app
```

Il vérifie le chargement mobile, le manifeste, le service worker et le
redémarrage hors connexion dans un profil temporaire. Il ne certifie ni
l'installation ni le rendu sur Safari/iPhone/Android réels.

Références : [installation sur iPhone (Apple)](https://support.apple.com/guide/iphone/open-as-web-app-iphea86e5236/27/ios/27),
[installation sur Android (Chrome)](https://developer.chrome.com/blog/how_chrome_helps_users_install_the_apps_they_value),
[Web apps sur Mac (Apple)](https://support.apple.com/en-gb/104996),
[navigateurs Web pris en charge (Flutter)](https://docs.flutter.dev/reference/supported-platforms).
