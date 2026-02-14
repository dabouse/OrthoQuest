#!/usr/bin/env python3
"""
Script d'optimisation des images de thèmes OrthoQuest.
Réduit la résolution et la taille des fichiers tout en conservant une bonne qualité visuelle.
"""
from pathlib import Path
import os

from PIL import Image

# Configuration
THEMES_DIR = Path(__file__).resolve().parent.parent / "assets" / "images" / "themes"
MAX_WIDTH = 1080  # Résolution Full HD adaptée aux écrans mobiles
PNG_QUALITY = 9  # 0-9, 9 = compression maximale
PNG_OPTIMIZE = True

THEME_FILES = [
    "boreal_aurore.png",
    "cyber_desert.png",
    "deep_space.png",
    "emerald_dream.png",
    "neon_default.png",
    "ocean_dive.png",
    "rose.png",
    "sunset.png",
    "tech_minute.png",
    "volcan.png",
]


def format_size(size_bytes: int) -> str:
    """Formate la taille en KB/MB."""
    if size_bytes < 1024:
        return f"{size_bytes} B"
    elif size_bytes < 1024 * 1024:
        return f"{size_bytes / 1024:.1f} KB"
    else:
        return f"{size_bytes / (1024 * 1024):.1f} MB"


def optimize_image(filepath: Path) -> tuple[int, int]:
    """Optimise une image PNG : redimensionne et compresse."""
    original_size = filepath.stat().st_size

    img = Image.open(filepath)
    img = img.convert("RGBA")

    # Calculer les nouvelles dimensions en conservant le ratio
    w, h = img.size
    if w > MAX_WIDTH:
        ratio = MAX_WIDTH / w
        new_w = MAX_WIDTH
        new_h = int(h * ratio)
        img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)

    # Sauvegarder avec compression optimisée
    img.save(
        filepath,
        "PNG",
        optimize=PNG_OPTIMIZE,
        compress_level=PNG_QUALITY,
    )
    new_size = filepath.stat().st_size
    return original_size, new_size


def main():
    if not THEMES_DIR.exists():
        print(f"Erreur: Dossier {THEMES_DIR} introuvable.")
        return 1

    total_before = 0
    total_after = 0

    print("Optimisation des images de thèmes...")
    print("-" * 50)

    for filename in THEME_FILES:
        filepath = THEMES_DIR / filename
        if not filepath.exists():
            print(f"  [!] {filename}: fichier introuvable")
            continue

        try:
            before, after = optimize_image(filepath)
            total_before += before
            total_after += after
            reduction = (1 - after / before) * 100 if before > 0 else 0
            print(f"  [OK] {filename}: {format_size(before)} -> {format_size(after)} (-{reduction:.0f}%)")
        except Exception as e:
            print(f"  [X] {filename}: erreur - {e}")

    print("-" * 50)
    total_reduction = (1 - total_after / total_before) * 100 if total_before > 0 else 0
    print(f"Total: {format_size(total_before)} -> {format_size(total_after)} (-{total_reduction:.0f}%)")
    return 0


if __name__ == "__main__":
    exit(main())
