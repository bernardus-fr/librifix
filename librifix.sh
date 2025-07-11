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
#  Script principal du programme, gère toutes les fonctions pricipales: verrou, initialisation
# des logs et appel de chaque script indépendant pour les travaux.


# Définition des Variables d'environnement:
source scripts/bash/utils_variables.sh
source scripts/bash/utils_fonctions.sh

# 1. GÉNÉRATION ET VÉRIFICATION D'INSTANCE
LOCK_FILE=".librifix.lock"
LOCK_TIMEOUT=7200  # Timeout en secondes (2 heures)
CURRENT_PID=${1:-$$}  # Utilise le PID fourni en argument ou le PID courant

# Vérifie si un verrou existe
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local lock_pid=$(cat "$LOCK_FILE" | cut -d':' -f1)
        local lock_time=$(cat "$LOCK_FILE" | cut -d':' -f2)

        # Vérifie si le processus est toujours actif
        if ps -p "$lock_pid" > /dev/null 2>&1; then
            afficher_message "info" "$LANG_TEXT_LOCK_EXEC $lock_pid"
            exit 1
        else
            # Vérifie si le verrou est expiré
            local current_time=$(date +%s)
            if (( current_time - lock_time > LOCK_TIMEOUT )); then
                afficher_message "warning" "$LANG_TEXT_LOCK_OBS"
                rm -f "$LOCK_FILE"
            else
                afficher_message "info" "$LANG_TEXT_LOCK_ACT"
                exit 1
            fi
        fi
    fi
}

# Crée un verrou
create_lock() {
    echo "${CURRENT_PID}:$(date +%s)" > "$LOCK_FILE"
    # se détruit automatiquement lors de l'arrêt du programme
    trap "remove_lock" EXIT
}

# Supprime le verrou
remove_lock() {
    if [ -f "$LOCK_FILE" ] && [ "$(cat $LOCK_FILE | cut -d':' -f1)" == "$CURRENT_PID" ]; then
        rm -f "$LOCK_FILE"
    fi
}

# Vérification et gestion
check_lock
create_lock

# --------------------------------------------------------------



# 2. INITIALISATION DU PROGRAMME
#    A) Initialisation des logs
"$LOG" create
if [ $? -ne 0 ]; then
    echo "Erreur lors de l'activation des logs. Arrêt du programme."
    exit 1
fi
"$LOG" add DEBUG "Logs activés - Initialisaton du programme"
#    -----------------

#   B) Initilisation du programme
if [[ ! -f "$CONFIG_FILE" ]]; then
    # Premier lancement du programme
    "$LOG" add DEBUG "Premier lancement détecté"

    "$LOG" add DEBUG "Création de $CONFIG_FILE"
    initialize_config

    "$LOG" add DEBUG "Analyse de l'intégrité du programme..."
    check_program_integrity
    "$LOG" add DEBUG "Analyse de l'intégrité du programme [OK]"

    "$LOG" add DEBUG "Analyse de la présence des dépendances"
    check_and_install_system_dependencies
    "$LOG" add DEBUG "Dépendances system [OK]"
    check_and_install_python_dependencies
    "$LOG" add DEBUG "Dépendances python [OK]"
else
    # Vérifier le dernier exit du programme
    check_last_exit_status
    if [ $? -ne 0 ]; then
        # Le dernier exit indiquait une erreur
        "$LOG" add WARNING "Erreur lors de la dernière fermeture du programme - Analyse..."

        "$LOG" add DEBUG "Analyse de l'intégrité du programme..."
        check_program_integrity
        "$LOG" add DEBUG "Analyse de l'intégrité du programme [OK]"

        "$LOG" add DEBUG "Analyse de la présence des dépendances..."
        check_and_install_system_dependencies
        "$LOG" add DEBUG "Dépendances system [OK]"
        check_and_install_python_dependencies
        "$LOG" add DEBUG "Dépendances python [OK]"
    else
        "$LOG" add DEBUG "Dernier exit : [OK]"
    fi
fi

# --------------------------------------------------------------


# Ajout d'une entrée dans les logs pour le début de l'exécution
"$LOG" add DEBUG "Début de l'exécution du script principal."

# 3. PROGRAMME PRINCIPAL
#    A) Activation du dossier temporaire temp/
"$LOG" add DEBUG "┌---- Exécution check_temp.sh ----"
# recherche d'un dossier temp + choix s'il existe:
source "$CHECK_TEMP"
"$LOG" add DEBUG "├---- Sortie de check_temp.sh ----"

#    -----------------

#   B) Gestion des métadonnées temp/metadata.json

"$LOG" add DEBUG "│ GESTION DES METADONNÉES"
if (( !TEMP_STATUS )); then
    # Dossier temp/ n'existe pas -> Nouvelle session
    # Appel au script de gestion des métadonnées avec interface graphique
    "$LOG" add DEBUG "├---- Exécution de metadata_manager.sh ----"
    source "$META_MANAG"
    "$LOG" add DEBUG "├---- Sortie de metadata_manager.sh ----"
fi

# Vérification de l'identifient du livre:
"$LOG" add DEBUG "│ VÉRIFICATION IDENTIFIENT DU LIVRE"
"$LOG" add DEBUG "├---- Exécution uuid_gen.py ----"
distr_python "$GEN_UUID"
"$LOG" add DEBUG "├---- Sortie de uuid_gen.py ----"

#    -----------------

#   C) Création des dossiers de travail: creation de la structure de l'epub, copie des fichiers utilisateur.
"$LOG" add DEBUG "│ CRÉATION STRUCTURE EPUB"
"$LOG" add DEBUG "├---- Exécution work_dir.sh ----"
"$TRAIT_WORKDIR"
if [ $? -ne 0 ]; then
    "$LOG" add ERROR "Erreur de traitement du script work_dir.sh"
    afficher_message error "$LANG_TEXT_ERROR_WORKDIR $LANG_MESSAGE_EXIT"
    "$EXIT_SCRIPT" "error"
    exit 1
fi
"$LOG" add DEBUG "├---- Sortie de work_dir.sh ----"

#    -----------------

#   D) Mise à jour des métadonnées dans les fichiers de base epub
"$LOG" add DEBUG "│ MISE À JOUR MÉTADONNÉES DANS FICHIERS DE BASE"
"$LOG" add DEBUG "├--- Exécution maj_meta_content.py ----"
distr_python "$UPDATE_META_CONTENT"
"$LOG" add DEBUG "├---- Sortie de maj_meta_content.py ----"

"$LOG" add DEBUG "├---- Exécution maj_meta_toc.py ----"
distr_python "$UPDATE_META_TOC"
"$LOG" add DEBUG "├---- Sortie de maj_meta_toc.py ----"

"$LOG" add DEBUG "├---- Exécution maj_meta_garde.py ----"
distr_python "$UPDATE_META_GARDE"
"$LOG" add DEBUG "├---- Sortie de maj_meta_garde.py ----"

"$LOG" add DEBUG "├---- Exécution maj_meta_nav.py ----"
distr_python "$UPDATE_META_NAV"
"$LOG" add DEBUG "├---- Sortie de maj_nav.py ----"

#    -----------------

#   E) Traitement des fichiers utilisateur
"$LOG" add DEBUG "│ TRAITEMENT DES FICHIERS UTILISATEUR"
# - Analyse des fichiers utilisateurs:
"$LOG" add DEBUG "│ - Analyser fichiers utilisateur -"
"$LOG" add DEBUG "├---- Exécution analyse_files.py ----"
distr_python "$ANALYSE_FILES"
"$LOG" add DEBUG "├---- Sortie de analyse_files.py ----"

# - Insersion des fichiers dans la sturture temporaire
"$LOG" add DEBUG "├---- Exécution insert_user_files.sh ----"
"$INSERT_FILES"
if [ $? -ne 0 ]; then
    "$LOG" add ERROR "Erreur de traitement du script insert_user_files.sh"
    afficher_message error "$LANG_TEXT_ERROR_INSERT_FILES $LANG_MESSAGE_EXIT"
    "$EXIT_SCRIPT" "error"
    exit 1
fi
"$LOG" add DEBUG "├---- Sortie de insert_user_files.sh ----"

#    -----------------

#   F) Compilation de l'EPUB et vérification de conformité
"$LOG" add DEBUG "├---- Exécution epubizer.sh ----"
"$EPUBIZER"
if [ $? -ne 0 ]; then
    "$LOG" add ERROR "Erreur de traitement du script epubizer.sh"
    afficher_message error "$LANG_TEXT_ERROR_EPUBIZER $LANG_MESSAGE_EXIT"
    "$EXIT_SCRIPT" "error"
    exit 1
fi
"$LOG" add DEBUG "└---- Sortie de epubizer.sh ----"

# Fin de l'exécution
"$LOG" add DEBUG "Fin de l'exécution du script principal."
"$EXIT_SCRIPT" "success"

exit 0
