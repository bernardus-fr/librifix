#!/bin/bash

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


PY_DIR="scripts/py"
BASH_DIR="scripts/bash"
MAN_JSON="$PY_DIR/manage_json.py"
LOG="./$BASH_DIR/log_manager.sh"
TEMP_DIR="temp"
WORKDIR="$TEMP_DIR/workdir"
USER_FILES_JSON="$TEMP_DIR/user_files.json"

"$LOG" add INFO "│ Début du script de gestion des fichiers à insérer dans l'EPUB."

# Mise à jour de user_files.json
update_json() {
    local file="$1"
    python3 "$MAN_JSON" update-status "$file" OK
    if [[ $? -eq 0 ]]; then
        "$LOG" add INFO "│ Fichier marqué comme traité dans user_files.json : $file"
    else
        "$LOG" add ERROR "│ Échec de la mise à jour de user_files.json pour : $file"
    fi
}

# Vérification du fichier user_files.json
if [[ ! -f "$USER_FILES_JSON" ]]; then
    "$LOG" add ERROR "│ Fichier $USER_FILES_JSON introuvable ."
    exit 1
fi

# Boucle principale pour traiter les fichiers
while true; do
    # Récupérer le premier fichier non traité via un script Python
    next_file=$(python3 "$MAN_JSON" get-first)

    if [[ "$next_file" == "none" ]]; then
        "$LOG" add INFO "│ Aucun fichier à traiter dans user_files.json."
        break
    elif [[ "$next_file" == *ERROR* ]]; then
        "$LOG" add ERROR "│ Une erreur s'est produite : ${next_file#ERROR:}"
        break
    fi

    "$LOG" add INFO "│ Fichier à traiter : $next_file"

    # Déterminer le type de fichier
    file_extension="${next_file##*.}"
    "$LOG" add INFO "│ Extension du fichier détectée : $file_extension"

    case "$file_extension" in
        # Traitement des images
        jpg|jpeg|png|gif)
            "$LOG" add INFO "│ Fichier Image détecté."
            ./scripts/bash/traitement_images.sh "$next_file"
            update_json "$next_file"
            ;;

        # Traitement des fichiers texte
        txt)
            "$LOG" add INFO "│ Fichier Texte détecté. Vérification des fichiers associés."
            linked_notes=$(python3 "$MAN_JSON" find-note "$next_file")

            if [[ "$linked_notes" == "none" ]]; then
                "$LOG" add INFO "│ Aucun fichier de notes associé trouvé."
                ./scripts/bash/traitement_xhtml.sh "$next_file"
                update_json "$next_file"
            elif [[ "$linked_notes" == *ERROR* ]]; then
                "$LOG" add ERROR "│ Une erreur s'est produite lors de la recherche des notes : ${linked_notes#ERROR:}"
            else
                "$LOG" add INFO "│ Fichiers de notes associés trouvés : $linked_notes"
                ./scripts/bash/traitement_xhtml.sh "$next_file" "$linked_notes"
                update_json "$next_file"
                update_json "$linked_notes"
            fi
            ;;

        # Traitement des autres types de fichiers
        *)
            "$LOG" add WARNING "│ Type de fichier inconnu ou autre détecté."
            ./scripts/bash/traitement_autres.sh "$next_file"
            update_json "$next_file"
            ;;
    esac

done

"$LOG" add INFO "│ Fin du script de gestion des fichiers."

exit 0
