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
#  Script du traitement des fichiers texte: analyse le type de fichiers: Type chapitre - Type notes.
# Synchronise les notes avec le chapitre si besoin est, Référence les notes dans les deux fichiers
# et ajoute le html de base. S'il n'y a qu'un fichiers de type chapitre, simple ajout du html.
# Utilisation: ./traitement_xhtml.sh <fichier_chapitre>
#              ./traitement_xhtml.sh <fichier_chapitre> <fichiers_notes>


# Définition des Variables d'environnement:
#source scripts/bash/utils.sh
source scripts/bash/utils_variables.sh
source scripts/bash/utils_fonctions.sh

# Vérification de l'argument pour le dossier
if [ $# -eq 0 ]; then
    "$LOG" add ERROR "Usage : ./traitement.sh <chapitre[X].txt> <notes_chapitre[X].txt>"
    exit 1
fi

# Récupération des noms de fichier dans les arguments
CHAPITRE_TXT="$WORKDIR/$1"
if [[ -n "$2" ]]; then
    NOTES_TXT="$WORKDIR/$2"
    "$LOG" add DEBUG "│ Fichier notes à traiter : $NOTES_TXT"
fi

# Vérification de la présence des scripts
if [[ ! -f "$SYNC_CHAP_NOTES" || ! -f "$TRAIT_NOTES_REF" || ! -f "$TRAIT_CHAP_REF" || ! -f "$TRAIT_CHAP_HTML" || ! -f "$TRAIT_NOTES_HTML" ]]; then
    "$LOG" add ERROR "│ Un ou plusieurs scripts Python sont manquants. Vérifiez leur présence."
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
	local notes_out="$TXT_DIR/${index_notes}.xhtml"

	# Variables utiles Texte
	local texte_modif="$WORKDIR/${index_texte}_modif.txt"
	local texte_xhtml="${index_texte}.xhtml"
	local texte_out="$TXT_DIR/${index_texte}.xhtml"

	# Étape 1 : Synchronisation des notes
    distr_python "$SYNC_CHAP_NOTES" "$texte" "$notes" "$notes_sync"
    if [[ $? -ne 0 ]]; then
        "$LOG" add ERROR "│ Synchronisation : Erreur de traitement pour $texte et $notes"
        exit 1
    fi
    "$LOG" add DEBUG "│ Synchronisation réussie pour $texte et $notes : $notes_sync"

    # Étape 2 : Traitement des notes synchronisées
    distr_python "$TRAIT_NOTES_REF" "$notes_sync" "$texte_xhtml" "$notes_modif"
    if [[ $? -ne 0 ]]; then
    	"$LOG" add ERROR "│ Erreur lors du traitement de : $notes_sync"
        exit 1
    fi
    distr_python "$TRAIT_NOTES_HTML" "$index_notes" "$notes_modif" "$notes_out"
    if [[ $? -ne 0 ]]; then
    	"$LOG" add ERROR "│ Erreur lors du traitement de : $notes_modif"
        exit 1
    fi
    "$LOG" add DEBUG "│ Traitement des notes Terminé: $notes_xhtml"

    # Étape 3 : Traitement du chapitre
    distr_python "$TRAIT_CHAP_REF" "$texte" "$notes_xhtml" "$texte_modif"
    if [[ $? -ne 0 ]]; then
    	"$LOG" add ERROR "│ Erreur lors du traitement de : $texte"
        exit 1
    fi
    distr_python "$TRAIT_CHAP_HTML" "$index_texte" "$texte_modif" "$texte_out"
    if [[ $? -ne 0 ]]; then
    	"$LOG" add ERROR "│ Erreur lors du traitement de : $texte_modif"
        exit 1
    fi
    "$LOG" add DEBUG "│ Traitement du texte Terminé: $texte_xhtml"

    # Suppression des fichiers temporaires
    rm "$notes_sync"
    rm "$notes_modif"
    rm "$texte_modif"
    "$LOG" add DEBUG "│ Fichiers temporaires supprimés: $notes_sync $notes_modif $texte_modif"

    # Mise à jour du manifest et de la table des matières
    distr_python "$PY_DIR/update_manifest.py" "Text/${index_texte}.xhtml"
    distr_python "$PY_DIR/update_manifest.py" "Text/${index_notes}.xhtml"
    "$LOG" add INFO "│ <manifest> mis à jour avec: Text/${index_texte}.xhtml Text/${index_notes}.xhtml"
    distr_python "$PY_DIR/update_index.py" "${index_texte}.xhtml"
    "$LOG" add INFO "│ Index mis à jour avec: Text/${index_texte}.xhtml"
}

treat_no_notes() {
	local texte="$1"

	# Récupération basename
	local index_texte="${texte##*/}"
	local index_texte="${index_texte%.*}"

	# Variables utiles Texte
	local texte_xhtml="${index_texte}.xhtml"
	local texte_out="$TXT_DIR/${index_texte}.xhtml"

	# Génération du html
    distr_python "$TRAIT_CHAP_HTML" "$index_texte" "$texte" "$texte_out"
    if [[ $? -ne 0 ]]; then
    	"$LOG" add ERROR "│ Erreur lors du traitement de : $texte"
        exit 1
    fi
    "$LOG" add DEBUG "│ Traitement du texte Terminé: $texte_xhtml"

    # Mise à jour du manifest
    distr_python "$PY_DIR/update_manifest.py" "Text/${index_texte}.xhtml"
    "$LOG" add DEBUG "│ <manifest> mis à jour avec: Text/${index_texte}.xhtml"
    distr_python "$PY_DIR/update_index.py" "${index_texte}.xhtml"
    "$LOG" add DEBUG "│ Index mis à jour avec: Text/${index_texte}.xhtml"
}

if [[ -n "$NOTES_TXT" ]]; then
	treat_with_notes "$CHAPITRE_TXT" "$NOTES_TXT"
    "$LOG" add DEBUG "│ Traitement Terminé: $CHAPITRE_TXT $NOTES_TXT"
    exit 0
elif [[ -z "$NOTES_TXT" ]]; then
	treat_no_notes "$CHAPITRE_TXT"
    "$LOG" add DEBUG "│ Traitement Terminé: $CHAPITRE_TXT"
    exit 0
fi

exit 1
