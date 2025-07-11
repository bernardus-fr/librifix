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
#  Définir les variables d'environnement


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
UPDATE_META_NAV="$PY_DIR/maj_meta_nav.py"
MAN_JSON="$PY_DIR/manage_json.py"
UPDATE_MANIFEST="$PY_DIR/update_manifest.py"
UPDATE_INDEX="$PY_DIR/update_index.py"

# Fichiers de données
CURRENT_LOG="$LOG_DIR/current.log"
METADATA_FILE="$TEMP_DIR/metadata.json"
USER_FILES_JSON="$TEMP_DIR/user_files.json"
CONFIG_FILE="config.ini"
ISO_LANG="./lang/iso_code_lang.json"

# Variables générales du programme
TEMP_STATUS=0   # 0 = pas de dossier temp, 1 = temp existant

# Détecter la distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    #echo "Distribution système détectée $DISTRO"
elif command -v lsb_release &>/dev/null; then
    DISTRO=$(lsb_release -i | awk -F: '{print $2}' | xargs)
    #echo "Distribution système détectée $DISTRO"
else
    echo "Impossible de détecter la distribution."
fi

# Définition des alias selon la distribution
case "$DISTRO" in
    ubuntu|debian|linuxmint)
        distr_python() { python3 "$@"; }
        distr_magick_convert() { convert "$@"; }
        ;;
    fedora|centos|rhel)
        distr_python() { python3 "$@"; }
        distr_magick_convert() { magick "$@"; }
        ;;
    opensuse*)
        distr_python() { python3.12 "$@"; }
        distr_magick_convert() { magick "$@"; }
        ;;
    arch|cachyos)
        distr_magick_convert() { magick convert "$@"; }
        distr_python() { python3.13 "$@"; }
        ;;
    *)
        echo "Distribution non supportée. Certaines commandes peuvent ne pas fonctionner."
        ;;
esac

# Configuration des variables de traduction
# Traduction de l'interface
if [[ -f "$CONFIG_FILE" ]]; then
    # Recherche de la langue
    SYS_LANG=$(grep "^language=" "$CONFIG_FILE" | cut -d '=' -f2)
else
    SYS_LANG=$(locale | grep "^LANG=" | cut -d= -f2 | cut -d_ -f1)
fi

LANG_FILE="lang/interface/${SYS_LANG}.json"
if [[ ! -f "$LANG_FILE" ]]; then
    LANG_FILE="lang/interface/en.json"
fi
EPUB_LANGS_FILE="lang/epub/${SYS_LANG}.txt"
if [[ ! -f "$EPUB_LANGS_FILE" ]]; then
    EPUB_LANGS_FILE="lang/epub/fr.txt"
fi

# Définition des variables provenant du lang.json e.g. LANG_TITLE_ERROR...
eval "$(jq -r 'paths(scalars) as $p | "LANG_" + ($p | map(ascii_upcase) | join("_")) + "=\"" + getpath($p) + "\""' "$LANG_FILE")"
