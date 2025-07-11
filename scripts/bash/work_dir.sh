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
#  Mise en place des dossiers et fichiers temporaires de travail: copie du dossier utilisateur
# dans workdir, copie du template epub dans epub_temp.


# Définition des Variables d'environnement:
source scripts/bash/utils_variables.sh
source scripts/bash/utils_fonctions.sh

# 1. VÉRIFICATIONS
# Vérification et création du répertoire temporaire
if [ ! -d "$TEMP_DIR" ]; then
  mkdir -p "$TEMP_DIR"
  "$LOG" add DEBUG "│ Répertoire temporaire absent : $TEMP_DIR - Creation du dossier !"
fi

# --------------------------------------------------------------



# 2. COPIE DU RÉPERTOIRE UTILISATEUR
# 	A) Lecture du chemin utilisateur depuis metadata.json
USER_WORKDIR=$(jq -r '.workdir' "$METADATA_FILE")
if [ -z "$USER_WORKDIR" ] || [ ! -d "$USER_WORKDIR" ]; then
  "$LOG" add ERROR "│ Erreur : le chemin utilisateur défini dans metadata.json est invalide ou inexistant."
  afficher_message error "$LANG_MESSAGE_INVALID_DIR"
  exit 1
fi

"$LOG" add DEBUG "│ Dossier utilisateur détecté : $USER_WORKDIR"

# 	B) Copie du dossier utilisateur dans temp/
cp -r "$USER_WORKDIR" "$WORKDIR"
"$LOG" add DEBUG "│ Dossier utilisateur copié dans : $WORKDIR"

# --------------------------------------------------------------



# 3. COPIE DE LE STRUCTURE EPUB
# Copie du template EPUB dans temp/
if [ ! -d "$TEMPLATE_DIR" ]; then
  "$LOG" add ERROR "│ Template absent : $TEMPLATE_DIR"
  afficher_message error "$LANG_MESSAGE_FILE_NOT_FOUND : $TEMPLATE_DIR. $LANG_MESSAGE_CHECK_INTEGRITY"
  exit 1
fi
cp -r "$TEMPLATE_DIR" "$EPUB_TEMP"
"$LOG" add DEBUG "│ Structure EPUB copiée dans : $EPUB_TEMP"

exit 0