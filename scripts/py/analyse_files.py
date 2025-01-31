# Librifix - Open Source Software
# Copyright (C) 2025 Bernard Langlet
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.


import os
import json
from pathlib import Path
import subprocess

# Variables globales
INPUT_DIR = "temp/workdir"
OUTPUT_JSON = "temp/user_files.json"

# Gestion des logs
def log_message(level, message):
    subprocess.run(["./scripts/bash/log_manager.sh", "add", level, message], check=True)

# Ordre des fichiers
FILE_ORDER_BY_PREFIX = [
    "cover",
    "4cover",
    "page_de_garde",
    "preface",
    "introduction",
    "chapitre",
    "complement",
    "notes_preface",
    "notes_introduction",
    "notes_chapitre",
    "notes_complement",
]

FILE_ORDER_BY_EXTENSION = {
    "css": 1,
    "ttf": 2,
}

# Fonction pour catégoriser un fichier
def categorize_file(filename):
    if filename.lower() in ["cover.jpg", "cover.png", "cover.jpeg"]:
        return "traiter"
    elif filename.lower() in ["4cover.jpg", "4cover.png", "4cover.jpeg"]:
        return "traiter"
    elif filename.lower() == "page_de_garde.xhtml":
        return "traiter"
    elif filename.lower() == "preface.txt":
        return "traiter"
    elif filename.lower() == "introduction.txt":
        return "traiter"
    elif filename.lower().startswith("chapitre") and filename.lower().endswith(".txt"):
        return "traiter"
    elif filename.lower().startswith("complement") and filename.lower().endswith(".txt"):
        return "traiter"
    elif filename.lower().startswith("notes") and filename.lower().endswith(".txt"):
        return "traiter"
    elif filename.lower().endswith(".css"):
        return "traiter"
    elif filename.lower().endswith(".ttf"):
        return "traiter"
    else:
        return "non reconnu"

# Fonction pour définir une clé de tri
def sort_key(file):
    base_name = Path(file).stem.lower()
    extension = Path(file).suffix.lower().lstrip(".")

    # Priorité du préfixe
    prefix_priority = len(FILE_ORDER_BY_PREFIX) + 1  # Par défaut, fichier inconnu
    for i, prefix in enumerate(FILE_ORDER_BY_PREFIX):
        if base_name.startswith(prefix):
            prefix_priority = i
            break

    # Extraire le numéro pour les fichiers avec un numéro
    number = float("inf")  # Par défaut, pas de numéro
    for prefix in ["chapitre", "complement", "notes_chapitre", "notes_complement"]:
        if base_name.startswith(prefix):
            num_part = "".join(filter(str.isdigit, base_name))
            number = int(num_part) if num_part.isdigit() else float("inf")
            break

    # Priorité de l'extension
    extension_priority = FILE_ORDER_BY_EXTENSION.get(extension, len(FILE_ORDER_BY_EXTENSION) + 1)

    # Clé combinée
    return (prefix_priority, number, extension_priority)

# Analyse des fichiers utilisateur et génération du fichier JSON
def analyze_user_files(input_dir, output_json):
    files_status = {}
    
    # Analyser les fichiers présents
    log_message("INFO", f"│ Analyse du dossier : {input_dir}")
    all_files = []
    for root, _, files in os.walk(input_dir):
        for file in files:
            filepath = Path(root) / file
            all_files.append(file)
            status = categorize_file(file)
            files_status[file] = status

    # Trier les fichiers selon l'ordre défini
    sorted_files = sorted(all_files, key=sort_key)

    # Réorganiser le dictionnaire selon l'ordre trié
    ordered_files_status = {file: files_status[file] for file in sorted_files}

    # Sauvegarde du fichier JSON
    os.makedirs(os.path.dirname(output_json), exist_ok=True)
    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(ordered_files_status, f, ensure_ascii=False, indent=4)

    log_message("INFO", f"│ Fichier JSON généré : {output_json}")

# Exemple d'utilisation
if __name__ == "__main__":
    analyze_user_files(INPUT_DIR, OUTPUT_JSON)
