# Guide de publication OrthoQuest sur Google Play Store

## Prérequis

- [x] Compte Google Play Developer créé (ID: 4814380934511245610)
- [x] Clé de signature générée (`android/app/upload-keystore.jks`)
- [x] Configuration Gradle pour la signature release
- [x] App Bundle signé (`build/app/outputs/bundle/release/app-release.aab`)
- [x] Politique de confidentialité (`privacy_policy.html`)
- [ ] Validation d'identité Google Play (en cours)
- [ ] Validation de l'accès à un appareil Android
- [ ] Validation du numéro de téléphone

## 1. Terminer la configuration du compte Google Play

Avant de pouvoir publier, vous devez compléter les 3 validations sur
[Google Play Console](https://play.google.com/console) :

1. **Valider votre identité** : télécharger une pièce d'identité (passeport ou carte d'identité suisse)
2. **Confirmer l'accès à un appareil Android** : installer l'app Play Console sur votre téléphone OnePlus Nord
3. **Valider votre numéro de téléphone** : recevoir un code de vérification par SMS

> La validation d'identité peut prendre quelques jours.

## 2. Héberger la politique de confidentialité

La politique de confidentialité doit être accessible via une URL publique.
Options recommandées :

### Option A : GitHub Pages (gratuit, recommandé)

1. Pusher le fichier `privacy_policy.html` sur votre dépôt GitHub
2. Aller dans Settings > Pages de votre repo
3. Activer GitHub Pages (source: main branch)
4. L'URL sera : `https://VOTRE_USERNAME.github.io/OrthoQuest/privacy_policy.html`

### Option B : Hébergement direct sur GitHub

1. Pusher le fichier `privacy_policy.html` sur votre dépôt
2. Aller sur le fichier dans GitHub, cliquer "Raw"
3. Utiliser un service comme [htmlpreview.github.io](https://htmlpreview.github.io/) pour afficher la page

## 3. Créer l'application dans Google Play Console

1. Aller sur [Google Play Console](https://play.google.com/console)
2. Cliquer **"Créer une application"**
3. Remplir les informations :
   - **Nom de l'application** : OrthoQuest
   - **Langue par défaut** : Français (France)
   - **Application ou Jeu** : Application
   - **Gratuite ou Payante** : Gratuite
4. Accepter les déclarations et créer

## 4. Fiche Play Store (Store Listing)

### 4.1 Description

**Description courte** (80 caractères max) :
```
Suivi ludique du port d'appareil dentaire pour enfants et ados
```

**Description complète** (4000 caractères max) :
```
OrthoQuest transforme le suivi du port d'appareil dentaire en une aventure motivante !

Conçue pour les enfants et adolescents en traitement orthodontique, OrthoQuest aide à suivre le temps de port quotidien de l'appareil, avec un objectif de 12 à 13 heures par jour.

FONCTIONNALITÉS PRINCIPALES :

⏱ Suivi du temps de port
Lance le chronomètre quand tu mets ton appareil, arrête-le quand tu le retires. OrthoQuest enregistre automatiquement tes sessions et calcule ton temps de port quotidien grâce à une jauge circulaire intuitive.

🪥 Minuteur de brossage
Un minuteur de 2 minutes pour s'assurer d'un brossage optimal, avec des animations amusantes et un retour sonore.

🏆 Système de récompenses
Gagne 10 XP par heure de port et 50 XP par brossage ! Monte de niveau, débloque des badges et des thèmes visuels exclusifs pour personnaliser ton application.

📊 Statistiques détaillées
Consulte tes statistiques hebdomadaires et mensuelles sous forme de graphiques. Exporte tes rapports en PDF pour les montrer à ton orthodontiste !

🔥 Série quotidienne
Maintiens ta série en atteignant ton objectif chaque jour. Plus ta série est longue, plus tu gagnes de récompenses !

🎨 Thèmes personnalisables
Débloque jusqu'à 10 thèmes visuels différents (Néon, Espace, Aurore Boréale, Émeraude...) en montant de niveau.

RESPECT DE LA VIE PRIVÉE :
OrthoQuest ne collecte aucune donnée personnelle. Toutes les données sont stockées uniquement sur ton appareil. Aucun compte requis, aucune publicité.

Développée avec amour en Suisse 🇨🇭
```

### 4.2 Éléments graphiques requis

| Élément | Format | Dimensions |
|---------|--------|-----------|
| **Icône de l'app** | PNG 32 bits | 512 x 512 px |
| **Feature Graphic** | PNG ou JPEG | 1024 x 500 px |
| **Screenshots** | PNG ou JPEG | Min. 2, max. 8 par type d'appareil |

**Icône** : Utilisez le fichier `assets/images/logo.png` (redimensionnez à 512x512 si nécessaire).

**Screenshots** : Prenez des captures d'écran depuis l'émulateur ou votre appareil :
- Écran d'accueil avec la jauge de progression
- Écran de brossage
- Écran de statistiques
- Écran de badges/récompenses
- Écran des thèmes

> Les captures `flutter_01.png` et `flutter_02.png` à la racine du projet peuvent servir de base.

**Feature Graphic** : Image promotionnelle de 1024x500 pour le bandeau en haut de la fiche.
Vous pouvez la créer avec Canva, Figma, ou tout éditeur graphique.

### 4.3 Catégorisation

- **Catégorie** : Santé et remise en forme
- **Tags** : Orthodontie, Dentaire, Suivi, Enfants

## 5. Content Rating (Classification du contenu)

1. Aller dans **Politique > Classification du contenu**
2. Cliquer **"Commencer le questionnaire"**
3. Répondre aux questions IARC :
   - **Catégorie** : Utilitaire / Productivité
   - Pas de violence, pas de contenu sexuel, pas de jeux de hasard
   - Pas d'achat intégré
   - Pas de partage de position
   - Pas de contenu généré par les utilisateurs
4. Résultat attendu : **PEGI 3** / **Tout le monde**

## 6. Public cible et contenu

1. Aller dans **Politique > Public cible et contenu**
2. **Tranche d'âge cible** : Sélectionner "Moins de 13 ans", "13-15 ans" et "16-17 ans"
3. Comme l'app cible aussi les mineurs de moins de 13 ans, Google peut demander une conformité supplémentaire :
   - L'app ne collecte aucune donnée → conforme
   - Pas de publicité → conforme
   - Pas de compte utilisateur → conforme

> **Important** : Si Google considère que l'app est principalement destinée aux enfants,
> elle peut être soumise au programme "Conçu pour les familles". Cela impose des
> règles supplémentaires mais donne aussi une meilleure visibilité dans le Play Store.

## 7. Déclaration de sécurité des données

1. Aller dans **Politique > Sécurité des données**
2. Répondre :
   - **L'app collecte-t-elle des données ?** → Non
   - **L'app partage-t-elle des données ?** → Non
   - **L'app utilise-t-elle le chiffrement ?** → Non applicable (données locales uniquement)
   - **Possibilité de suppression des données** → Oui (désinstallation ou reset dans l'app)

## 8. Politique de confidentialité

1. Aller dans **Politique > Politique de confidentialité**
2. Coller l'URL publique de votre page `privacy_policy.html`

## 9. Upload de l'App Bundle et Release

### 9.1 Activer Play App Signing

1. Aller dans **Release > Configuration > Signature de l'application**
2. **Accepter Play App Signing** (recommandé par Google)
   - Google gère la clé de signature finale
   - Vous uploadez avec votre clé "upload"
   - Si vous perdez votre clé upload, Google peut en générer une nouvelle

### 9.2 Créer une release

1. Aller dans **Release > Production**
2. Cliquer **"Créer une release"**
3. Uploader le fichier : `build/app/outputs/bundle/release/app-release.aab`
4. **Nom de la release** : `2.0.0`
5. **Notes de version** :
```
Version initiale de OrthoQuest !

• Suivi du temps de port d'appareil dentaire
• Minuteur de brossage de 2 minutes
• Système de niveaux et badges
• Statistiques hebdomadaires et mensuelles
• Export PDF des rapports
• 10 thèmes visuels à débloquer
• Série quotidienne et récompenses
```
6. Cliquer **"Vérifier la release"** puis **"Commencer le déploiement en Production"**

### 9.3 Alternative : Test interne d'abord

Si vous voulez tester avant la publication officielle :
1. Aller dans **Release > Tests > Test interne**
2. Créer une release de test interne avec le même AAB
3. Ajouter des testeurs (adresses e-mail)
4. Les testeurs pourront installer l'app via un lien privé
5. Une fois validé, promouvoir en Production

## 10. Après la publication

- **Délai de review** : 1 à 7 jours pour la première publication
- **URL de la fiche** : `https://play.google.com/store/apps/details?id=com.orthoquest.ortho_quest`
- **Mises à jour** : pour publier une mise à jour, incrémentez le `versionCode` dans `pubspec.yaml` et uploadez un nouveau AAB

## Fichiers importants

| Fichier | Description | Git |
|---------|-------------|-----|
| `android/app/upload-keystore.jks` | Clé de signature upload | **NE PAS COMMITTER** |
| `android/key.properties` | Configuration de la clé | **NE PAS COMMITTER** |
| `privacy_policy.html` | Politique de confidentialité | OK |
| `build/app/outputs/bundle/release/app-release.aab` | App Bundle signé | Généré |

## Sauvegarde de la clé de signature

> **CRITIQUE** : Sauvegardez `upload-keystore.jks` et `key.properties` dans un endroit sûr
> (clé USB, gestionnaire de mots de passe, coffre-fort numérique).
> Si vous perdez ces fichiers et n'avez pas activé Play App Signing,
> vous ne pourrez plus mettre à jour votre application sur le Play Store.

**Mot de passe du keystore** : `OrthoQuest2026!`
**Alias** : `upload`

Il est recommandé de changer ce mot de passe pour un mot de passe plus sécurisé :
```bash
keytool -storepasswd -keystore android/app/upload-keystore.jks
```
