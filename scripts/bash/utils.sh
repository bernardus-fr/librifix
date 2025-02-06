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
#  Définir les variables d'environnement, fonctions récurentes, etc et centraliser
# les récurences dans le code pour alléger chaque script.


# DÉFINITION DES VARIABLES D'ENVIRONNEMENT
# Répertoires de travail
BASH_DIR="./scripts/bash"
PY_DIR="./scripts/py"
TEMP_DIR="./temp"
WORKDIR="$TEMP_DIR/workdir"
EPUB_TEMP="$TEMP_DIR/epub_temp"
OEBPS_TEMP="$EPUB_TEMP/OEBPS"
TXT_DIR="$OEBPS_TEMP/Text"
IMG_DIR="$OEBPS_TEMP/Images"
FONT_DIR="$OEBPS_TEMP/Fonts"
STYLE_DIR="$OEBPS_TEMP/Styles"
TEMPLATE_DIR="./utils/templates/epub"
LOG_DIR="logs"
ERROR_DIR="$LOG_DIR/errors"

# Scripts bash
LOG="$BASH_DIR/log_manager.sh"
EXIT_SCRIPT="$BASH_DIR/exit.sh"
CHECK_TEMP="$BASH_DIR/check_temp.sh"
META_MANAG="$BASH_DIR/metadata_manager.sh"
TRAIT_WORKDIR="$BASH_DIR/work_dir.sh"
INSERT_FILES="$BASH_DIR/insert_user_files.sh"
TRAIT_XHTML="$BASH_DIR/traitement_xhtml.sh"
TRAIT_IMG="$BASH_DIR/traitement_images.sh"
TRAIT_OTH="$BASH_DIR/traitement_autres.sh"
EPUBIZER="$BASH_DIR/epubizer.sh"

# Scripts python
GEN_UUID="$PY_DIR/uuid_gen.py"
ANALYSE_FILES="$PY_DIR/analyse_files.py"
SYNC_CHAP_NOTES="$PY_DIR/synch.py"
TRAIT_CHAP_REF="$PY_DIR/chapitre.py"
TRAIT_NOTES_REF="$PY_DIR/notes.py"
TRAIT_CHAP_HTML="$PY_DIR/gen_html_chap.py"
TRAIT_NOTES_HTML="$PY_DIR/gen_html_notes.py"
GEN_COVER="$PY_DIR/generate_cover.py"
UPDATE_META_CONTENT="$PY_DIR/maj_meta_content.py"
UPDATE_META_GARDE="$PY_DIR/maj_meta_garde.py"
UPDATE_META_TOC="$PY_DIR/maj_meta_toc.py"
MAN_JSON="$PY_DIR/manage_json.py"
UPDATE_MANIFEST="$PY_DIR/update_manifest.py"
UPDATE_INDEX="$PY_DIR/update_index.py"

# Fichiers de données
CURRENT_LOG="$LOG_DIR/current.log"
METADATA_FILE="$TEMP_DIR/metadata.json"
USER_FILES_JSON="$TEMP_DIR/user_files.json"

# Variables générales du programme
TEMP_STATUS=0   # 0 = pas de dossier temp, 1 = temp existant


# DÉFINITION DES FONCTIONS RÉCURENTES
# Affichage d'une fenêtre d'ereur Zenity
afficher_fenetre_erreur() {
    local message="$1"
    zenity --error --title="Erreur" --text="$message"
}

# Affichage d'une fenêtre d'info Zenity
afficher_fenetre_info() {
    local message="$1"
    zenity --info --title="Information" --text="$message"
}