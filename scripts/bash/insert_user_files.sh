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



#       FONCTION DU SCRIPT:
#  Script d'insersion des fichiers de l'utilisateur dans la structure temporaire epub_temp.
# Se base sur la liste des fichiers déclarée dans user_files.json, et les gère un par un
# en fonction de leur extension
#  Recherche des fichiers avec manage_json.py et après analyse, les envoie au script adéquat
# selon l'extension: traitement_xhtml.sh, traitement_image.sh, traitement_autre.sh.
#  Après chaque traitement le fichier json est mis à jour.


# Définition des Variables d'environnement:
source scripts/bash/utils.sh

# Définition des Fonctions:
# Mise à jour de user_files.json
update_json() {
    local file="$1"
    distr_python "$MAN_JSON" update-status "$file" OK
    if [[ $? -eq 0 ]]; then
        "$LOG" add DEBUG "│ Fichier marqué comme traité dans user_files.json : $file"
    else
        "$LOG" add ERROR "│ Échec de la mise à jour de user_files.json pour : $file"
    fi
}

"$LOG" add DEBUG "│ Début du script de gestion des fichiers à insérer dans l'EPUB."

# Vérification du fichier user_files.json
if [[ ! -f "$USER_FILES_JSON" ]]; then
    "$LOG" add ERROR "│ Fichier $USER_FILES_JSON introuvable."
    afficher_message error "$LANG_MESSAGE_FILE_NOT_FOUND: $USER_FILES_JSON."
    exit 1
fi

# Boucle principale pour traiter les fichiers
while true; do
    # Récupérer le premier fichier non traité via un script Python
    next_file=$(distr_python "$MAN_JSON" get-first)

    if [[ "$next_file" == "none" ]]; then
        "$LOG" add DEBUG "│ Aucun fichier à traiter dans user_files.json."
        break
    elif [[ "$next_file" == *ERROR* ]]; then
        "$LOG" add ERROR "│ Une erreur s'est produite : ${next_file#ERROR:}"
        break
    fi

    "$LOG" add DEBUG "│ Fichier à traiter : $next_file"

    # Déterminer le type de fichier
    file_extension="${next_file##*.}"
    "$LOG" add DEBUG "│ Extension du fichier détectée : $file_extension"

    case "$file_extension" in
        # Traitement des images
        jpg|jpeg|png|gif)
            "$LOG" add DEBUG "│ Fichier Image détecté."
            ./scripts/bash/traitement_images.sh "$next_file"
            update_json "$next_file"
            ;;

        # Traitement des fichiers texte
        txt)
            "$LOG" add DEBUG "│ Fichier Texte détecté. Vérification des fichiers associés."
            linked_notes=$(distr_python "$MAN_JSON" find-note "$next_file")

            if [[ "$linked_notes" == "none" ]]; then
                "$LOG" add DEBUG "│ Aucun fichier de notes associé trouvé."
                ./scripts/bash/traitement_xhtml.sh "$next_file"
                update_json "$next_file"
            elif [[ "$linked_notes" == *ERROR* ]]; then
                "$LOG" add ERROR "│ Une erreur s'est produite lors de la recherche des notes : ${linked_notes#ERROR:}"
            else
                "$LOG" add DEBUG "│ Fichiers de notes associés trouvés : $linked_notes"
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



"$LOG" add DEBUG "│ Fin du script de gestion des fichiers."

exit 0
