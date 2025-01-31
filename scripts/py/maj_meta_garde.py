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
import subprocess
from bs4 import BeautifulSoup

# Chemins des fichiers
metadata_file = "temp/metadata.json"
language_codes_file = "utils/language_codes.json"
cover_page_file = "temp/epub_temp/OEBPS/Text/page_de_garde.xhtml"

# Gestion des logs
def log_message(level, message):
    subprocess.run(["./scripts/bash/log_manager.sh", "add", level, message], check=True)

# Chargement des métadonnées
def load_metadata():
    if not os.path.exists(metadata_file):
        log_message("ERROR", f"│ Le fichier {metadata_file} est introuvable.")
        raise FileNotFoundError(f"Le fichier {metadata_file} est introuvable.")

    with open(metadata_file, "r", encoding="utf-8") as f:
        metadata = json.load(f)

    # Vérification des champs obligatoires
    for field in ["title", "creator", "publisher", "language"]:
        if field not in metadata or not metadata[field].strip():
            log_message("ERROR", f"│ Le champ obligatoire '{field}' est manquant ou vide dans les métadonnées.")
            raise ValueError(f"Le champ obligatoire '{field}' est manquant ou vide dans les métadonnées.")

    log_message("INFO", "│ Méta-données chargées avec succès.")
    return metadata

# Chargement de la correspondance des codes de langue
def load_language_codes():
    if not os.path.exists(language_codes_file):
        log_message("ERROR", f"│ Le fichier {language_codes_file} est introuvable.")
        raise FileNotFoundError(f"Le fichier {language_codes_file} est introuvable.")

    with open(language_codes_file, "r", encoding="utf-8") as f:
        language_map = json.load(f)

    log_message("INFO", "│ Fichier de codes de langues chargé avec succès.")
    return language_map

# Conversion du nom de la langue en code ISO
def get_language_code(language_name, language_map):
    language_name_lower = language_name.strip().lower()
    return language_map.get(language_name_lower, language_name_lower)

def update_cover_page(metadata, language_map):
    try:
        # Ouvrir et lire le fichier HTML de la page de garde
        log_message("INFO", f"│ Ouverture de {cover_page_file}")
        with open(cover_page_file, 'r', encoding='utf-8') as file:
            soup = BeautifulSoup(file, 'html.parser')

        log_message("INFO", "│ Inscription des métadonnées")

        # Mise à jour de la langue dans la balise <html>
        language_code = get_language_code(metadata["language"], language_map)
        html_tag = soup.find('html')
        if html_tag:
            html_tag['xml:lang'] = language_code
            html_tag['lang'] = language_code

        log_message("INFO", f"│ Langue mise à jour {metadata["language"]}")

        # Mise à jour des informations dans les balises appropriées
        # Remplacer le texte dans <h1>, <p> par les métadonnées
        author_tag = soup.find('p', class_="auteur")
        if author_tag:
            author_tag.string = metadata["creator"]

        log_message("INFO", f"│ Auteur mise à jour {metadata["creator"]}")

        title_tag = soup.find('h1')
        if title_tag:
            title_tag.string = metadata["title"]

        log_message("INFO", f"│ Titre mise à jour {metadata["title"]}")

        publisher_tag = soup.find('p', class_="editeur")
        if publisher_tag:
            publisher_tag.string = metadata["publisher"]

        log_message("INFO", f"│ Éditeur mise à jour {metadata["publisher"]}")

        # Sauvegarder les modifications dans un nouveau fichier HTML
        log_message("INFO", f"│ Écriture du fichier {cover_page_file}")
        with open(cover_page_file, 'w', encoding='utf-8') as file:
            file.write(str(soup))

    except Exception as e:
        log_message("ERROR", f"│ Erreur lors de la mise à jour de la page de garde : {e}")

# Programme principal
def main():
    try:
        log_message("INFO", "│ Début de la mise à jour de la page de garde.")
        metadata = load_metadata()
        language_map = load_language_codes()
        update_cover_page(metadata, language_map)
        log_message("INFO", "│ Mise à jour de la page de garde terminée avec succès.")
    except Exception as e:
        log_message("ERROR", f"│ Erreur : {e}")
        print(f"Erreur : {e}")

if __name__ == "__main__":
    main()
