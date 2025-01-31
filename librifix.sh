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


#!/bin/bash

# Définir les répertoires pour les scripts
BASH_DIR="./scripts/bash"
PY_DIR="./scripts/py"

EXIT_SCRIPT="./scripts/bash/exit.sh"

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
            zenity --info --title="Instance Active" \
                --text="Une autre instance du programme est déjà en cours d'exécution (PID : $lock_pid). Veuillez réessayer plus tard." \
                --timeout=10
            exit 1
        else
            # Vérifie si le verrou est expiré
            local current_time=$(date +%s)
            if (( current_time - lock_time > LOCK_TIMEOUT )); then
                zenity --warning --title="Verrou Expiré" \
                    --text="Un verrou obsolète a été trouvé et sera supprimé."
                rm -f "$LOCK_FILE"
            else
                zenity --info --title="Instance Active" \
                    --text="Un verrou actif est en cours, mais le processus associé est mort.\nVeuillez attendre la fin du timeout ou réessayer plus tard." \
                    --timeout=10
                exit 1
            fi
        fi
    fi
}

# Crée un verrou
create_lock() {
    echo "${CURRENT_PID}:$(date +%s)" > "$LOCK_FILE"
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



# 2. ACTIVATION DES LOGS
"$BASH_DIR/log_manager.sh" create
if [ $? -ne 0 ]; then
    echo "Erreur lors de l'activation des logs. Arrêt du programme."
    exit 1
fi

# Ajout d'une entrée dans les logs pour le début de l'exécution
"$BASH_DIR/log_manager.sh" add INFO "Début de l'exécution du script principal."

# --------------------------------------------------------------



# 3. PROGRAMME PRINCIPAL
#    A) Activation du dossier temporaire temp/
"$BASH_DIR/log_manager.sh" add INFO "┌---- Exécution check_temp.sh ----"
# recherche d'un dossier temp + choix s'il existe:
"$BASH_DIR/check_temp.sh"
temp_status=$?
"$BASH_DIR/log_manager.sh" add INFO "├---- Sortie de check_temp.sh ----"

#    -----------------

#   B) Gestion des métadonnées temp/metadata.json

"$BASH_DIR/log_manager.sh" add INFO "│ GESTION DES METADONNÉES"
if [ $temp_status -eq 1 ]; then
    # Dossier temp/ n'existe pas -> Nouvelle session
    # Appel au script de gestion des métadonnées avec interface graphique
    "$BASH_DIR/log_manager.sh" add INFO "├---- Exécution de metadata_manager.sh ----"
    "$BASH_DIR/metadata_manager.sh"
    if [ $? -ne 0 ]; then
        "$BASH_DIR/log_manager.sh" add CRITICAL "Annulation, extinction du programme. - Retour incorrect de metadata_manager.sh"
        "$EXIT_SCRIPT"
        exit 1
    fi
    "$BASH_DIR/log_manager.sh" add INFO "├---- Sortie de metadata_manager.sh ----"
fi

# Vérification de l'identifient du livre:
"$BASH_DIR/log_manager.sh" add INFO "│ VÉRIFICATION IDENTIFIENT DU LIVRE"
"$BASH_DIR/log_manager.sh" add INFO "├---- Exécution uuid_gen.py ----"
python3 "$PY_DIR/uuid_gen.py"
"$BASH_DIR/log_manager.sh" add INFO "├---- Sortie de uuid_gen.py ----"

#    -----------------

#   C) Création des dossiers de travail: creation de la structure de l'epub, copie des fichiers utilisateur.
"$BASH_DIR/log_manager.sh" add INFO "│ CRÉATION STRUCTURE EPUB"
"$BASH_DIR/log_manager.sh" add INFO "├---- Exécution work_dir.sh ----"
"$BASH_DIR/work_dir.sh"
if [ $? -ne 0 ]; then
    "$BASH_DIR/log_manager.sh" add CRITICAL "Annulation, extinction du programme. - Retour incorrect de work_dir.sh"
    "$EXIT_SCRIPT"
    exit 1
fi
"$BASH_DIR/log_manager.sh" add INFO "├---- Sortie de work_dir.sh ----"

#    -----------------

#   D) Mise à jour des métadonnées dans les fichiers de base epub
"$BASH_DIR/log_manager.sh" add INFO "│ MISE À JOUR MÉTADONNÉES DANS FICHIERS DE BASE"
"$BASH_DIR/log_manager.sh" add INFO "├--- Exécution maj_meta_content.py ----"
python3 "$PY_DIR/maj_meta_content.py"
"$BASH_DIR/log_manager.sh" add INFO "├---- Sortie de maj_meta_content.py ----"

"$BASH_DIR/log_manager.sh" add INFO "├---- Exécution maj_meta_toc.py ----"
python3 "$PY_DIR/maj_meta_toc.py"
"$BASH_DIR/log_manager.sh" add INFO "├---- Sortie de maj_meta_toc.py ----"

"$BASH_DIR/log_manager.sh" add INFO "├---- Exécution maj_meta_garde.py ----"
python3 "$PY_DIR/maj_meta_garde.py"
"$BASH_DIR/log_manager.sh" add INFO "├---- Sortie de maj_meta_garde.py ----"

#    -----------------

#   E) Traitement des fichiers utilisateur
"$BASH_DIR/log_manager.sh" add INFO "│ TRAITEMENT DES FICHIERS UTILISATEUR"
# - Analyse des fichiers utilisateurs:
"$BASH_DIR/log_manager.sh" add INFO "│ - Analyser fichiers utilisateur -"
"$BASH_DIR/log_manager.sh" add INFO "├---- Exécution analyse_files.py ----"
python3 "$PY_DIR/analyse_files.py"
"$BASH_DIR/log_manager.sh" add INFO "├---- Sortie de analyse_files.py ----"

# - Insersion des fichiers dans la sturture temporaire
"$BASH_DIR/log_manager.sh" add INFO "├---- Exécution insert_user_files.sh ----"
"$BASH_DIR/insert_user_files.sh"
"$BASH_DIR/log_manager.sh" add INFO "├---- Sortie de insert_user_files.sh ----"

"$BASH_DIR/epubizer.sh"

# Fin de l'exécution
"$BASH_DIR/log_manager.sh" add INFO "Fin de l'exécution du script principal."
"$BASH_DIR/log_manager.sh" close

