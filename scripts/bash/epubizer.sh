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
#  Création de l'archive epub et vérification de conformité


# Définir les variables de répertoires et de fichiers
EPUB_DIR="temp/epub_temp"
EPUB_FILE="temp/livre.epub"
META_INF_DIR="$EPUB_DIR/META-INF"
OEBPS_DIR="$EPUB_DIR/OEBPS"
LOG="./scripts/bash/log_manager.sh"
CHECK="utils/epubcheck-5.2.0/epubcheck.jar"

# Vérifier que le répertoire temp/epub_temp existe
if [ ! -d "$EPUB_DIR" ]; then
    "$LOG" add ERROR "│ Le dossier $EPUB_DIR n'existe pas. Abandon de la création de l'EPUB."
    exit 1
fi

# Vérifier la présence des fichiers nécessaires dans META-INF et OEBPS
if [ ! -d "$META_INF_DIR" ] || [ ! -d "$OEBPS_DIR" ]; then
    "$LOG" add ERROR "Les fichiers nécessaires dans $META_INF_DIR ou $OEBPS_DIR sont manquants. Abandon de la création de l'EPUB."
    exit 1
fi

# Créer l'archive EPUB
"$LOG" add DEBUG "│ Création de l'archive EPUB..."

# Créer un fichier zip et ajouter tous les fichiers et dossiers nécessaires
cd "$EPUB_DIR"
zip -Xr ../livre.epub mimetype * -x "*.DS_Store"
cd - || exit 1

cp "$EPUB_FILE" "livre.epub"
EPUB_FILE="livre.epub"

"$LOG" add DEBUG "│ L'EPUB a été créé avec succès sous le nom $EPUB_FILE."

# Vérification de la conformité avec les normes epub.
if [[ ! -f "$CHECK" ]]; then
    "$LOG" add WARNING "│ EPUBCHECK n'a pas été trouvé, Impossible de vérifier la conformité epub."
else
    "$LOG" add DEBUG "│ Vérification de conformité avec EPUBCHECK..."
    java -jar "$CHECK" "$EPUB_FILE"
fi

# Exécution du livre dans ebook-viewer
if command -v ebook-viewer &> /dev/null; then
    "$LOG" add DEBUG "│ ebook-viewer présent dans le système, ouverture du livre..."
    ebook-viewer "$EPUB_FILE" &
fi

exit 0