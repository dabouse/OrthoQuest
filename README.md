# OrthoQuest 🦷

OrthoQuest est une application mobile ludique conçue pour aider les enfants (et les ados !) à suivre le temps de port de leur appareil dentaire.

L'objectif est d'atteindre une durée cible quotidienne (par défaut 12-13h) pour gagner des récompenses virtuelles (stickers, flammes de série).

## 📱 Fonctionnalités

-   **Suivi du temps de port** : Timer simple Start/Stop.
-   **Objectif visuel** : Jauge circulaire pour voir la progression de la journée.
-   **Règle des 5h du matin** : Une "journée" de port se termine à 5h du matin le lendemain. Cela permet de compter une nuit complète de sommeil sur la même date (essentiel pour l'orthodontie).
-   **Timer de Brossage** : Un minuteur de 2 minutes avec animation et son pour accompagner le brossage des dents.
-   **Statistiques** : Graphique des 7 derniers jours pour voir la régularité.
-   **Stickers** : Un petit système de notes/humeur pour chaque session.

## 🛠 Stack Technique

-   **Framework** : [Flutter](https://flutter.dev/)
-   **Langage** : Dart
-   **Base de Données** : SQLite (via `sqflite`)
-   **Gestion d'État** : Riverpod (Architecture `NotifierProvider`)
-   **Graphiques** : `fl_chart`
-   **Animations** : `lottie`, `avatar_glow`

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

## ⚙️ Configuration

Les réglages (durée de brossage, heure de fin de journée) sont stockés en base de données localement.

## 📝 Auteur

Développé pour OrthoQuest.
