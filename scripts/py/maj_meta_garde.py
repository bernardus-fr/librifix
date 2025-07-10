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


#       FONCTION DU SCRIPT:
#  Simple mise à jour de la page de garde du template avec les données entrées par l'utilisateur
# et conservées dans les metadata.json: Titre, Auteur, Éditeur, Langue.


import os
import json
from bs4 import BeautifulSoup
from LibFix import utils

# Chemins des fichiers
metadata_file = "temp/metadata.json"
language_codes_file = "utils/language_codes.json"
cover_page_file = "temp/epub_temp/OEBPS/Text/page_de_garde.xhtml"

# Chargement des métadonnées
def load_metadata():
    if not os.path.exists(metadata_file):
        utils.log_message("ERROR", f"│ Le fichier {metadata_file} est introuvable.")
        raise FileNotFoundError(f"Le fichier {metadata_file} est introuvable.")

    with open(metadata_file, "r", encoding="utf-8") as f:
        metadata = json.load(f)

    # Vérification des champs obligatoires
    for field in ["title", "creator", "publisher", "language"]:
        if field not in metadata or not metadata[field].strip():
            utils.log_message("ERROR", f"│ Le champ obligatoire '{field}' est manquant ou vide dans les métadonnées.")
            raise ValueError(f"Le champ obligatoire '{field}' est manquant ou vide dans les métadonnées.")

    utils.log_message("DEBUG", "│ Méta-données chargées avec succès.")
    return metadata

def update_cover_page(metadata):
    try:
        # Ouvrir et lire le fichier HTML de la page de garde
        utils.log_message("DEBUG", f"│ Ouverture de {cover_page_file}")
        with open(cover_page_file, 'r', encoding='utf-8') as file:
            soup = BeautifulSoup(file, 'html.parser')

        utils.log_message("DEBUG", "│ Inscription des métadonnées")

        # Mise à jour de la langue dans la balise <html>
        html_tag = soup.find('html')
        if html_tag:
            html_tag['xml:lang'] = metadata["language"]
            html_tag['lang'] = metadata["language"]

        utils.log_message("DEBUG", f"│ Langue mise à jour {metadata["language"]}")

        # Mise à jour des informations dans les balises appropriées
        # Remplacer le texte dans <h1>, <p> par les métadonnées
        author_tag = soup.find('p', class_="auteur")
        if author_tag:
            author_tag.string = metadata["creator"]

        utils.log_message("DEBUG", f"│ Auteur mise à jour {metadata["creator"]}")

        title_tag = soup.find('h1')
        if title_tag:
            title_tag.string = metadata["title"]

        utils.log_message("DEBUG", f"│ Titre mise à jour {metadata["title"]}")

        publisher_tag = soup.find('p', class_="editeur")
        if publisher_tag:
            publisher_tag.string = metadata["publisher"]

        utils.log_message("DEBUG", f"│ Éditeur mise à jour {metadata["publisher"]}")

        # Sauvegarder les modifications dans un nouveau fichier HTML
        utils.log_message("DEBUG", f"│ Écriture du fichier {cover_page_file}")
        with open(cover_page_file, 'w', encoding='utf-8') as file:
            file.write(str(soup))

    except Exception as e:
        utils.log_message("ERROR", f"│ Erreur lors de la mise à jour de la page de garde : {e}")

# Programme principal
def main():
    try:
        utils.log_message("DEBUG", "│ Début de la mise à jour de la page de garde.")
        metadata = load_metadata()
        update_cover_page(metadata)
        utils.log_message("DEBUG", "│ Mise à jour de la page de garde terminée avec succès.")
    except Exception as e:
        utils.log_message("ERROR", f"│ Erreur : {e}")
        print(f"Erreur : {e}")

if __name__ == "__main__":
    main()
