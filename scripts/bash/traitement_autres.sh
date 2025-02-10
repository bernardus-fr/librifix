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
#  Script du traitement des fichiers qui ne sont pas à retoucher, feuilles de style, fonts, etc,
# et déplacement dans les dossiers adéquats de la structure epub temporaire. Met à jours le
# manifeste avec le fichier intégré.
# Utilisation: ./traitement_autres.sh <fichier>


# Définition des Variables d'environnement:
source scripts/bash/utils.sh

# Vérification des arguments
if [[ $# -ne 1 ]]; then
    "$LOG" add ERROR "│ Usage : $0 <file_name>"
    exit 1
fi

file_name="$1"
source_file="$WORKDIR/$file_name"

# Vérification de l'existence du fichier
if [[ ! -f "$source_file" ]]; then
    "$LOG" add ERROR "│ Fichier introuvable : $source_file"
    exit 1
fi

# Détection du type de fichier et traitement
extension="${file_name##*.}"
"$LOG" add DEBUG "│ Fichier de type $extension trouvé"
case "$extension" in
    css)
        dest_subdir="Styles"
        ;;
    otf|ttf|woff|woff2)
        dest_subdir="Fonts"
        ;;
    xhtml|html)
        dest_subdir="Text"
        ;;
    svg)
        dest_subdir="Images"
        ;;
    *)
        "$LOG" add WARNING "│ Type de fichier inconnu : $file_name"
        exit 0
        ;;
esac

# Déplacement du fichier dans le dossier approprié
dest_path="$OEBPS_TEMP/$dest_subdir/$file_name"
mkdir -p "$OEBPS_TEMP/$dest_subdir"
if cp "$source_file" "$dest_path"; then
    "$LOG" add DEBUG "│ Fichier déplacé vers : $dest_path"
    # Mise à jour du manifest avec le script Python
    relative_path="${dest_subdir}/${file_name}"
    if distr_python "$UPDATE_MANIFEST" "$relative_path"; then
        "$LOG" add DEBUG "│ Fichier ajouté au manifest via le script Python : $relative_path"
    else
        "$LOG" add ERROR "│ Échec de la mise à jour du manifest pour : $relative_path"
        exit 1
    fi
else
    "$LOG" add ERROR "│ Échec du déplacement de : $file_name"
    exit 1
fi

exit 0
