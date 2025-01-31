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


import json
import sys
import subprocess

USER_FILES_PATH = "temp/user_files.json"

# Gestion des logs
def log_message(level, message):
    subprocess.run(["./scripts/bash/log_manager.sh", "add", level, message], check=True)

# Charger le contenu du fichier user_files.json.
def load_user_files():
    try:
        with open(USER_FILES_PATH, "r", encoding="utf-8") as file:
            return json.load(file)
    except FileNotFoundError:
        log_message("ERROR", f"{USER_FILES_PATH} introuvable.")
        sys.exit(1)
    except json.JSONDecodeError:
        log_message("ERROR", f"Le fichier {USER_FILES_PATH} contient des erreurs JSON.")
        sys.exit(1)

# Enregistrer les données dans le fichier user_files.json.
def save_user_files(data):
    try:
        with open(USER_FILES_PATH, "w", encoding="utf-8") as file:
            json.dump(data, file, indent=4, ensure_ascii=False)
    except Exception as e:
        log_message("ERROR", f"Impossible d'enregistrer les données dans {USER_FILES_PATH}: {e}")
        sys.exit(1)

# Récupérer le premier fichier non traité.
def get_first_unprocessed():
    data = load_user_files()
    for file_name, status in data.items():
        if status == "traiter":
            return file_name
        if status == "non reconnu":
            return file_name
    return None

# Trouver une note correspondante à un fichier donné.
def find_corresponding_note(file_name):
    data = load_user_files()
    note_file_name = f"notes_{file_name}"
    return note_file_name if note_file_name in data else None

# Mettre à jour le statut d'un fichier.
def update_file_status(file_name, new_status):
    data = load_user_files()
    if file_name in data:
        data[file_name] = new_status
        save_user_files(data)
        log_message("INFO", f"Statut de {file_name} mis à jour en {new_status}.")
        return True
    log_message("WARNING", f"Fichier {file_name} non trouvé dans user_files.json.")
    return False

# Programme principal
def main():
    if len(sys.argv) < 2:
        log_message("ERROR", "Usage: python user_files_manager.py <action> [arguments]")
        sys.exit(1)

    action = sys.argv[1]

    if action == "get-first":
        result = get_first_unprocessed()
        if result:
            print(result)
            #log_message("INFO", f"Premier fichier à traiter : {result}")
            sys.exit(0)
        else:
            print("none")
            #log_message("INFO", "Aucun fichier à traiter trouvé.")
            sys.exit(0)

    elif action == "find-note":
        if len(sys.argv) < 3:
            log_message("ERROR", "Usage: python user_files_manager.py find-note <file_name>")
            sys.exit(1)
        file_name = sys.argv[2]
        result = find_corresponding_note(file_name)
        if result:
            print(result)
            #log_message("INFO", f"Note correspondante trouvée : {result}")
            sys.exit(0)
        else:
            print("none")
            #log_message("INFO", f"Aucune note trouvée pour {file_name}.")
            sys.exit(0)

    elif action == "update-status":
        if len(sys.argv) < 4:
            log_message("ERROR", "Usage: python user_files_manager.py update-status <file_name> <new_status>")
            sys.exit(1)
        file_name = sys.argv[2]
        new_status = sys.argv[3]
        if update_file_status(file_name, new_status):
            log_message("INFO", f"Statut mis à jour pour {file_name}.")
            sys.exit(0)

    else:
        log_message("ERROR", f"Action inconnue: {action}")
        sys.exit(1)

if __name__ == "__main__":
    main()
