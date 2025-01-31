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

# Chemins
TEMP_DIR="./temp"
TEMPLATE_DIR="./utils/templates/epub"
SCRIPT_DIR="./scripts/bash"
LOG_SCRIPT="$SCRIPT_DIR/log_manager.sh"
METADATA_FILE="$TEMP_DIR/metadata.json"
WORKDIR="$TEMP_DIR/workdir"
EPUB_TEMP="$TEMP_DIR/epub_temp"

# 1. VÉRIFICATIONS
# Vérification et création du répertoire temporaire
if [ ! -d "$TEMP_DIR" ]; then
  mkdir -p "$TEMP_DIR"
  "$LOG_SCRIPT" add WARNING "│ Répertoire temporaire absent : $TEMP_DIR - Creation du dossier !"
fi

# --------------------------------------------------------------



# 2. COPIE DU RÉPERTOIRE UTILISATEUR
# 	A) Lecture du chemin utilisateur depuis metadata.json
USER_WORKDIR=$(jq -r '.workdir' "$METADATA_FILE")
if [ -z "$USER_WORKDIR" ] || [ ! -d "$USER_WORKDIR" ]; then
  "$LOG_SCRIPT" add ERROR "│ Erreur : le chemin utilisateur défini dans metadata.json est invalide ou inexistant."
  zenity --info --title="Fichiers non trouvés" \
  		--text="Le chemin du dossier est invalide ou inexistant" \
        --timeout=10
  exit 1
fi

"$LOG_SCRIPT" add INFO "│ Dossier utilisateur détecté : $USER_WORKDIR"

# 	B) Copie du dossier utilisateur dans temp/
cp -r "$USER_WORKDIR" "$WORKDIR"
"$LOG_SCRIPT" add INFO "│ Dossier utilisateur copié dans : $WORKDIR"

# --------------------------------------------------------------



# 3. COPIE DE LE STRUCTURE EPUB
# Copie du template EPUB dans temp/
if [ ! -d "$TEMPLATE_DIR" ]; then
  "$LOG_SCRIPT" add ERROR "│ Template absent : $TEMPLATE_DIR"
  zenity --info --title="Fichiers manquants" \
  		--text="Certains fichiers ou dossier nécessaire au bon fonctionnement du programme sont absents, veuillez vérifier l'intégrité du programme" \
        --timeout=10
  exit 1
fi
cp -r "$TEMPLATE_DIR" "$EPUB_TEMP"
"$LOG_SCRIPT" add INFO "│ Structure EPUB copiée dans : $EPUB_TEMP"

exit 0