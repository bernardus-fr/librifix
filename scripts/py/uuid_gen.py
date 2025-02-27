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
#  Script de gestion d'identifiant unique obligatoire pour le livre, à partir des métadonnées
# s'il y a un ISBN existant, le programme s'arrête, s'il n'existe pas d'identifiant il en
# crée un.


import json
import uuid
import os
from LibFix import utils

# Définition des variables
file_path = "temp/metadata.json"

# Fonction pour générer un UUID
def generate_identifier():
    return str(uuid.uuid4())

# Fonction pour vérifier et mettre à jour le champ "identifier"
def update_identifier_in_metadata(file_path):
    # Vérifier si le fichier existe
    if not os.path.exists(file_path):
        utils.log_message("ERROR", f"│ Le fichier {file_path} est introuvable.")
        return

    # Ouvrir et lire le fichier JSON
    with open(file_path, 'r', encoding='utf-8') as f:
        metadata = json.load(f)

    # Vérifier si le champ "identifier" est vide
    if not metadata.get("identifier"):
        utils.log_message("INFO", "│ Identifiant manquant... Génération d'un UUID")
        # Générer un identifiant UUID et l'ajouter au champ "identifier"
        metadata["identifier"] = generate_identifier()
        utils.log_message("DEBUG", f"│ Identifiant généré : {metadata['identifier']}")

        # Sauvegarder les modifications dans le fichier
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(metadata, f, ensure_ascii=False, indent=4)

        utils.log_message("DEBUG", "│ Le fichier metadata.json a été mis à jour avec un nouvel identifiant.")
    else:
        utils.log_message("DEBUG", "│ Le champ 'identifier' est déjà rempli.")

# Fonction main pour lancer l'exécution
def main():
    utils.log_message("DEBUG", "│ Controle de l'identifiant du livre")
    update_identifier_in_metadata(file_path)
    utils.log_message("DEBUG", "│ Controle terminé")

# Appeler la fonction main pour exécuter le script
if __name__ == "__main__":
    main()
