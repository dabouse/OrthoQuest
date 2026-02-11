# ========================================
# Script de compilation OrthoQuest
# Version Finale (Release)
# ========================================
# Ce script permet de compiler l'application
# OrthoQuest en version finale pour différentes
# plateformes et formats.
# ========================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " COMPILATION OrthoQuest - Version Finale" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier que Flutter est installé
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    Write-Host "[ERREUR] Flutter n'est pas installé ou n'est pas dans le PATH" -ForegroundColor Red
    Write-Host "Veuillez installer Flutter: https://flutter.dev/docs/get-started/install"
    Read-Host "Appuyez sur Entrée pour quitter"
    exit 1
}

# Afficher la version de Flutter
Write-Host "[INFO] Version de Flutter:" -ForegroundColor Green
flutter --version | Select-String "Flutter"
Write-Host ""

# Menu de sélection du type de compilation
Write-Host "Choisissez le type de compilation:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. APK (Android) - Standard"
Write-Host "2. APK (Android) - Split par architecture"
Write-Host "3. App Bundle (Android) - Recommandé pour le Play Store"
Write-Host "4. Windows Desktop"
Write-Host "5. Nettoyer uniquement (flutter clean)"
Write-Host ""

$choice = Read-Host "Votre choix (1-5)"

if ($choice -eq "5") {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Nettoyage du projet..." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    flutter clean
    Write-Host "[INFO] Nettoyage terminé" -ForegroundColor Green
    Read-Host "Appuyez sur Entrée pour quitter"
    exit 0
}

# Confirmation avant de continuer
Write-Host ""
Write-Host "[ATTENTION] Cette opération va compiler l'application en mode release." -ForegroundColor Yellow
Write-Host "Cela peut prendre plusieurs minutes." -ForegroundColor Yellow
$confirm = Read-Host "Continuer? (O/N)"

if ($confirm -ne "O" -and $confirm -ne "o") {
    Write-Host "Opération annulée." -ForegroundColor Yellow
    Read-Host "Appuyez sur Entrée pour quitter"
    exit 0
}

# Nettoyage du projet
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Nettoyage du projet..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERREUR] Le nettoyage a échoué" -ForegroundColor Red
    Read-Host "Appuyez sur Entrée pour quitter"
    exit 1
}

# Récupération des dépendances
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Récupération des dépendances..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
$pubGetOutput = flutter pub get 2>&1 | Tee-Object -Variable pubGetResult
Write-Output $pubGetOutput

# Vérifier si c'est juste l'avertissement du mode développeur
if ($LASTEXITCODE -ne 0) {
    if ($pubGetOutput -like "*Developer Mode*" -or $pubGetOutput -like "*symlink support*") {
        Write-Host ""
        Write-Host "[AVERTISSEMENT] Mode développeur désactivé, mais tentative de continuation..." -ForegroundColor Yellow
        Write-Host "Pour éviter ce message, activez le Mode Développeur Windows:" -ForegroundColor Yellow
        Write-Host "  start ms-settings:developers" -ForegroundColor Cyan
        Write-Host ""
        
        # Vérifier si les dépendances sont déjà présentes
        if (Test-Path "pubspec.lock") {
            Write-Host "[INFO] Les dépendances semblent déjà présentes, continuation..." -ForegroundColor Green
        }
        else {
            Write-Host "[ERREUR] Les dépendances n'ont pas pu être récupérées" -ForegroundColor Red
            Write-Host "Veuillez activer le Mode Développeur et réessayer." -ForegroundColor Red
            Read-Host "Appuyez sur Entrée pour quitter"
            exit 1
        }
    }
    else {
        Write-Host "[ERREUR] La récupération des dépendances a échoué" -ForegroundColor Red
        Read-Host "Appuyez sur Entrée pour quitter"
        exit 1
    }
}

# Compilation selon le choix
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Compilation en cours..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$buildType = ""
$outputPath = ""

switch ($choice) {
    "1" {
        Write-Host "[INFO] Compilation APK standard..." -ForegroundColor Green
        flutter build apk --release
        $buildType = "APK"
        $outputPath = "build\app\outputs\flutter-apk\app-release.apk"
    }
    "2" {
        Write-Host "[INFO] Compilation APK split par architecture..." -ForegroundColor Green
        flutter build apk --release --split-per-abi
        $buildType = "APK (split)"
        $outputPath = "build\app\outputs\flutter-apk\"
    }
    "3" {
        Write-Host "[INFO] Compilation App Bundle..." -ForegroundColor Green
        flutter build appbundle --release
        $buildType = "App Bundle"
        $outputPath = "build\app\outputs\bundle\release\app-release.aab"
    }
    "4" {
        Write-Host "[INFO] Compilation Windows Desktop..." -ForegroundColor Green
        flutter build windows --release
        $buildType = "Windows"
        $outputPath = "build\windows\x64\runner\Release\"
    }
    default {
        Write-Host "[ERREUR] Choix invalide" -ForegroundColor Red
        Read-Host "Appuyez sur Entrée pour quitter"
        exit 1
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "[ERREUR] La compilation a échoué!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Read-Host "Appuyez sur Entrée pour quitter"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "[SUCCES] Compilation terminée!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Type de build: $buildType" -ForegroundColor Cyan
Write-Host "Fichier(s) généré(s): $outputPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Emplacement complet:" -ForegroundColor Yellow
Write-Host "$(Get-Location)\$outputPath"
Write-Host ""

# Proposer d'ouvrir le dossier
$openFolder = Read-Host "Voulez-vous ouvrir le dossier de sortie? (O/N)"
if ($openFolder -eq "O" -or $openFolder -eq "o") {
    switch ($choice) {
        "2" {
            explorer "$(Get-Location)\build\app\outputs\flutter-apk"
        }
        "4" {
            explorer "$(Get-Location)\build\windows\x64\runner\Release"
        }
        "3" {
            explorer "$(Get-Location)\build\app\outputs\bundle\release"
        }
        default {
            $directory = Split-Path -Parent "$(Get-Location)\$outputPath"
            explorer $directory
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Informations de build" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

if (Test-Path $outputPath) {
    if ($choice -eq "1") {
        Get-ChildItem "$outputPath" | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
    }
    elseif ($choice -eq "3") {
        Get-ChildItem "$outputPath" | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
    }
    elseif ($choice -eq "2") {
        Get-ChildItem "$outputPath" -Filter "*.apk" | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
    }
}

Write-Host ""
Read-Host "Appuyez sur Entrée pour quitter"
