@echo off
REM ========================================
REM Script de compilation OrthoQuest
REM Version Finale (Release)
REM ========================================
REM Ce script permet de compiler l'application
REM OrthoQuest en version finale pour différentes
REM plateformes et formats.
REM ========================================

setlocal enabledelayedexpansion

echo.
echo ========================================
echo  COMPILATION OrthoQuest - Version Finale
echo ========================================
echo.

REM Vérifier que Flutter est installé
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Flutter n'est pas installe ou n'est pas dans le PATH
    echo Veuillez installer Flutter: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

REM Afficher la version de Flutter
echo [INFO] Version de Flutter:
flutter --version | findstr "Flutter"
echo.

REM Menu de sélection du type de compilation
echo Choisissez le type de compilation:
echo.
echo 1. APK (Android) - Standard
echo 2. APK (Android) - Split par architecture
echo 3. App Bundle (Android) - Recommande pour le Play Store
echo 4. Windows Desktop
echo 5. Nettoyer uniquement (flutter clean)
echo.
set /p choice="Votre choix (1-5): "

if "%choice%"=="5" goto clean_only

REM Confirmation avant de continuer
echo.
echo [ATTENTION] Cette operation va compiler l'application en mode release.
echo Cela peut prendre plusieurs minutes.
set /p confirm="Continuer? (O/N): "
if /i not "%confirm%"=="O" (
    echo Operation annulee.
    pause
    exit /b 0
)

REM Nettoyage du projet
echo.
echo ========================================
echo Nettoyage du projet...
echo ========================================
flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] Le nettoyage a echoue
    pause
    exit /b 1
)

REM Récupération des dépendances
echo.
echo ========================================
echo Recuperation des dependances...
echo ========================================
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERREUR] La recuperation des dependances a echoue
    pause
    exit /b 1
)

REM Compilation selon le choix
echo.
echo ========================================
echo Compilation en cours...
echo ========================================

if "%choice%"=="1" goto build_apk
if "%choice%"=="2" goto build_apk_split
if "%choice%"=="3" goto build_appbundle
if "%choice%"=="4" goto build_windows

echo [ERREUR] Choix invalide
pause
exit /b 1

:build_apk
echo [INFO] Compilation APK standard...
flutter build apk --release
set BUILD_TYPE=APK
set OUTPUT_PATH=build\app\outputs\flutter-apk\app-release.apk
goto build_complete

:build_apk_split
echo [INFO] Compilation APK split par architecture...
flutter build apk --release --split-per-abi
set BUILD_TYPE=APK (split)
set OUTPUT_PATH=build\app\outputs\flutter-apk\
goto build_complete

:build_appbundle
echo [INFO] Compilation App Bundle...
flutter build appbundle --release
set BUILD_TYPE=App Bundle
set OUTPUT_PATH=build\app\outputs\bundle\release\app-release.aab
goto build_complete

:build_windows
echo [INFO] Compilation Windows Desktop...
flutter build windows --release
set BUILD_TYPE=Windows
set OUTPUT_PATH=build\windows\x64\runner\Release\
goto build_complete

:clean_only
echo.
echo ========================================
echo Nettoyage du projet...
echo ========================================
flutter clean
echo [INFO] Nettoyage termine
pause
exit /b 0

:build_complete
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo [ERREUR] La compilation a echoue!
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo [SUCCES] Compilation terminee!
echo ========================================
echo.
echo Type de build: %BUILD_TYPE%
echo Fichier(s) genere(s): %OUTPUT_PATH%
echo.
echo Emplacement complet:
echo %CD%\%OUTPUT_PATH%
echo.

REM Proposer d'ouvrir le dossier
set /p open_folder="Voulez-vous ouvrir le dossier de sortie? (O/N): "
if /i "%open_folder%"=="O" (
    if "%choice%"=="2" (
        explorer "%CD%\build\app\outputs\flutter-apk"
    ) else if "%choice%"=="4" (
        explorer "%CD%\build\windows\x64\runner\Release"
    ) else if "%choice%"=="3" (
        explorer "%CD%\build\app\outputs\bundle\release"
    ) else (
        for %%I in ("%OUTPUT_PATH%") do explorer "%%~dpI"
    )
)

echo.
echo ========================================
echo Informations de build
echo ========================================
echo Date: %DATE% %TIME%
if "%choice%"=="1" (
    if exist "%OUTPUT_PATH%" (
        dir "%OUTPUT_PATH%" | findstr "app-release.apk"
    )
) else if "%choice%"=="3" (
    if exist "%OUTPUT_PATH%" (
        dir "%OUTPUT_PATH%" | findstr "app-release.aab"
    )
)
echo.
pause
