# OrthoQuest 🦷

OrthoQuest est une application mobile ludique conçue pour aider les enfants (et les ados !) à suivre le temps de port de leur appareil dentaire.

L'objectif est d'atteindre une durée cible quotidienne (par défaut 12-13h) pour gagner des récompenses virtuelles (stickers, flammes de série).

## 📱 Fonctionnalités

-   **Suivi du temps de port** : Timer simple Start/Stop.
-   **Objectif visuel** : Jauge circulaire pour voir la progression de la journée.
-   **Interface responsive** : L'écran d'accueil s'adapte automatiquement à toutes les résolutions d'écran (jauge circulaire, boutons d'action, barres d'historique et barre de niveau se redimensionnent proportionnellement).
-   **Heure de fin de journée configurable** : Une "journée" de port se termine à l'heure configurée (par défaut minuit). Le temps de port après minuit est compté sur le jour courant. Les sessions traversant cette frontière sont automatiquement découpées entre les deux jours.
-   **Timer de Brossage** : Un minuteur de 5 minutes (configurable) avec animation et son pour accompagner le brossage des dents. Interface harmonisée avec le reste de l'app (cartes translucides, anneau avec bordures, boutons stylisés).
-   **Statistiques** : Graphique des 7 derniers jours pour voir la régularité.
-   **Stickers** : Un petit système de notes/humeur pour chaque session.
-   **Modifier / Supprimer une session** : Appui long sur un sticker de session (écran d'accueil ou statistiques) pour modifier les horaires, la durée, le sticker, ou supprimer la session. L'XP est automatiquement recalculée.
-   **Personnalisation** : Thèmes visuels débloqués par niveau. Les thèmes débloqués peuvent être définis en fond d'écran du téléphone en un clic (Android uniquement). Un indicateur de chargement s'affiche pendant l'opération.

## 🛠 Stack Technique

-   **Framework** : [Flutter](https://flutter.dev/)
-   **Langage** : Dart
-   **Base de Données** : SQLite (via `sqflite`)
-   **Gestion d'État** : Riverpod (Architecture `NotifierProvider`)
-   **Graphiques** : `fl_chart`
-   **Animations** : `lottie`, `avatar_glow`
-   **Fond d'écran** : implémentation native Android (canal Méthode) avec préservation des couleurs et traitement en arrière-plan

## ⚡ Optimisations de performance

- **Images de fond** : décodage à la taille d'affichage (`cacheWidth`/`cacheHeight`) pour éviter de bloquer le thread principal au démarrage.
- **Placeholder** : le dégradé du thème s'affiche immédiatement pendant le chargement de l'image de fond.

## 🖼️ Images de thèmes

Les fonds d'écran des thèmes sont optimisés pour garder une bonne qualité tout en limitant la taille de l'application. Pour ré-optimiser les images après ajout ou modification :

```bash
pip install Pillow
python scripts/optimize_themes.py
```

Le script redimensionne à 1080px de largeur (format mobile) et compresse les PNG.

## 📂 Structure du Projet

```
lib/
├── main.dart           # Point d'entrée de l'application
├── models/             # Modèles de données (Session, etc.)
├── providers/          # Gestion d'état (Timer logic)
├── services/           # Services (Base de données)
├── ui/
│   ├── screens/        # Écrans (Accueil, Brossage, Rapports)
│   └── widgets/        # Widgets réutilisables
└── utils/              # Utilitaires (Formatage, etc.)
```

## 🚀 Installation & Lancement

1.  **Pré-requis** : Avoir le Flutter SDK installé.
2.  **Récupérer les dépendances** :
    ```bash
    flutter pub get
    ```
3.  **Lancer l'application** :
    ```bash
    flutter run
    ```

## 🏗️ Build

Le script `build_release.ps1` génère automatiquement le fichier `lib/utils/build_info.dart` (version lue depuis `pubspec.yaml` + date du jour), puis lance le build. La version et la date sont affichées dans la page des paramètres.

```powershell
.\build_release.ps1
```

## ⚙️ Configuration

Les réglages sont stockés en base de données localement :
- **Heure de fin de journée** : L'heure à partir de laquelle une nouvelle journée commence (par défaut 0h = minuit). Les sessions terminées avant cette heure comptent pour le jour précédent.
- **Durée du brossage** : Durée du minuteur de brossage (par défaut 5 min).
- **Objectif quotidien** : Nombre d'heures de port cible par jour (par défaut 13h).

### Fond d'écran (Android)

La définition du fond d'écran s'effectue en arrière-plan : un indicateur de chargement apparaît pendant le traitement. Les images sont décodées avec préservation des couleurs natives (sans filtre d'assombrissement).

## 📝 Auteur

Développé pour OrthoQuest.
