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


# DÉFINITION DES VARIABLES D'ENVIRONNEMENT

LOG_SCRIPT="./scripts/bash/log_manager.sh"

# Vérification de l'argument pour le dossier
if [ $# -eq 0 ]; then
    "$LOG_SCRIPT" add ERROR "Usage : ./traitement.sh <chapitre[X].txt> <notes_chapitre[X].txt>"
    exit 1
fi

# Définition des dossiers
PY_DIR="scripts/py"
WORKDIR="temp/workdir"
OUT_DIR="temp/epub_temp/OEBPS/Text"

# Récupération des noms de fichier dans les arguments
CHAPITRE_TXT="$WORKDIR/$1"
if [[ -n "$2" ]]; then
    NOTES_TXT="$WORKDIR/$2"
    "$LOG_SCRIPT" add INFO "│ Fichier notes à traiter : $NOTES_TXT"
fi

# Scripts Python
SCRIPT_SYNC="$PY_DIR/synch.py"
SCRIPT_NOTES="$PY_DIR/notes.py"
SCRIPT_CHAPITRE="$PY_DIR/chapitre.py"
SCRIPT_GEN_CHAP="$PY_DIR/gen_html_chap.py"
SCRIPT_GEN_NOTES="$PY_DIR/gen_html_notes.py"

# Vérification de la présence des scripts
if [[ ! -f "$SCRIPT_SYNC" || ! -f "$SCRIPT_NOTES" || ! -f "$SCRIPT_CHAPITRE" || ! -f "$SCRIPT_GEN_CHAP" || ! -f "$SCRIPT_GEN_NOTES" ]]; then
    "$LOG_SCRIPT" add ERROR "Un ou plusieurs scripts Python sont manquants. Vérifiez leur présence."
    exit 1
fi

# TRAITEMENT AVEC LES NOTES
treat_with_notes() {
	local texte="$1"
	local notes="$2"

	# Récupération basename
	local index_texte="${texte##*/}"
	local index_texte="${index_texte%.*}"
	local index_notes="${notes##*/}"
	local index_notes="${index_notes%.*}"

	# Variables utiles Notes
	local notes_sync="$WORKDIR/${index_notes}_sync.txt"
	local notes_modif="$WORKDIR/${index_notes}_modif.txt"
	local notes_xhtml="${index_notes}.xhtml"
	local notes_out="$OUT_DIR/${index_notes}.xhtml"

	# Variables utiles Texte
	local texte_modif="$WORKDIR/${index_texte}_modif.txt"
	local texte_xhtml="${index_texte}.xhtml"
	local texte_out="$OUT_DIR/${index_texte}.xhtml"

	# Étape 1 : Synchronisation des notes
    python3 "$SCRIPT_SYNC" "$texte" "$notes" "$notes_sync"
    if [[ $? -ne 0 ]]; then
        "$LOG_SCRIPT" add ERROR "Synchronisation : Erreur de traitement pour $texte et $notes"
        exit 1
    fi
    "$LOG_SCRIPT" add INFO "Synchronisation réussie pour $texte et $notes : $notes_sync"

    # Étape 2 : Traitement des notes synchronisées
    python3 "$SCRIPT_NOTES" "$notes_sync" "$texte_xhtml" "$notes_modif"
    if [[ $? -ne 0 ]]; then
    	"$LOG_SCRIPT" add ERROR "Erreur lors du traitement de : $notes_sync"
        exit 1
    fi
    python3 "$SCRIPT_GEN_NOTES" "$index_notes" "$notes_modif" "$notes_out"
    if [[ $? -ne 0 ]]; then
    	"$LOG_SCRIPT" add ERROR "Erreur lors du traitement de : $notes_modif"
        exit 1
    fi
    "$LOG_SCRIPT" add INFO "Traitement des notes Terminé: $notes_xhtml"

    # Étape 3 : Traitement du chapitre
    python3 "$SCRIPT_CHAPITRE" "$texte" "$notes_xhtml" "$texte_modif"
    if [[ $? -ne 0 ]]; then
    	"$LOG_SCRIPT" add ERROR "Erreur lors du traitement de : $texte"
        exit 1
    fi
    python3 "$SCRIPT_GEN_CHAP" "$index_texte" "$texte_modif" "$texte_out"
    if [[ $? -ne 0 ]]; then
    	"$LOG_SCRIPT" add ERROR "Erreur lors du traitement de : $texte_modif"
        exit 1
    fi
    "$LOG_SCRIPT" add INFO "Traitement du texte Terminé: $texte_xhtml"

    # Suppression des fichiers temporaires
    rm "$notes_sync"
    rm "$notes_modif"
    rm "$texte_modif"
    "$LOG_SCRIPT" add INFO "Fichiers temporaires supprimés: $notes_sync $notes_modif $texte_modif"

    # Mise à jour du manifest et de la table des matières
    python3 "$PY_DIR/update_manifest.py" "Text/${index_texte}.xhtml"
    python3 "$PY_DIR/update_manifest.py" "Text/${index_notes}.xhtml"
    "$LOG_SCRIPT" add INFO "<manifest> mis à jour avec: Text/${index_texte}.xhtml Text/${index_notes}.xhtml"
    python3 "$PY_DIR/update_index.py" "${index_texte}.xhtml"
    "$LOG_SCRIPT" add INFO "Index mis à jour avec: Text/${index_texte}.xhtml"
}

treat_no_notes() {
	local texte="$1"

	# Récupération basename
	local index_texte="${texte##*/}"
	local index_texte="${index_texte%.*}"

	# Variables utiles Texte
	local texte_xhtml="${index_texte}.xhtml"
	local texte_out="$OUT_DIR/${index_texte}.xhtml"

	# Génération du html
    python3 "$SCRIPT_GEN_CHAP" "$index_texte" "$texte" "$texte_out"
    if [[ $? -ne 0 ]]; then
    	"$LOG_SCRIPT" add ERROR "Erreur lors du traitement de : $texte"
        exit 1
    fi
    "$LOG_SCRIPT" add INFO "Traitement du texte Terminé: $texte_xhtml"

    # Mise à jour du manifest
    python3 "$PY_DIR/update_manifest.py" "Text/${index_texte}.xhtml"
    "$LOG_SCRIPT" add INFO "<manifest> mis à jour avec: Text/${index_texte}.xhtml"
    python3 "$PY_DIR/update_index.py" "${index_texte}.xhtml"
    "$LOG_SCRIPT" add INFO "Index mis à jour avec: Text/${index_texte}.xhtml"
}

if [[ -n "$NOTES_TXT" ]]; then
	treat_with_notes "$CHAPITRE_TXT" "$NOTES_TXT"
    "$LOG_SCRIPT" add INFO "│ Traitement Terminé: $CHAPITRE_TXT $NOTES_TXT"
    exit 0
elif [[ -z "$NOTES_TXT" ]]; then
	treat_no_notes "$CHAPITRE_TXT"
    "$LOG_SCRIPT" add INFO "│ Traitement Terminé: $CHAPITRE_TXT"
    exit 0
fi

exit 1
