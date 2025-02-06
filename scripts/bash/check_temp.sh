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
#  Script de vérification des fichiers temporaires et choix s'il existe.


# Vérification de l'existence du dossier temp/
if [ -d "$TEMP_DIR" ]; then
    # Enregistrement des logs
    "$LOG" add DEBUG "│ Dossier temp déjà existant: exécution choix utilisateur"
    # Le dossier existe, demander à l'utilisateur ce qu'il souhaite faire
    ACTION=$(zenity --question --title="Projet existant" \
        --text="Il semble qu'un projet soit déjà en cours. Voulez-vous le reprendre ?" \
        --ok-label="Oui" --cancel-label="Non")

    if [ $? -eq 0 ]; then
        # L'utilisateur a choisi "Oui" (reprendre l'ancien projet) Enregistrement du log
        "$LOG" add DEBUG "│ Reprise ancien projet: [OK]"
        TEMP_STATUS=1
    else
        # L'utilisateur a choisi "Non" (repartir de zéro)
        rm -rf "$TEMP_DIR"/*   # Supprime uniquement le contenu du dossier temp/
        # Enregistrement des logs
        "$LOG" add DEBUG "│ Nouveau Projet, Vider dossier temp/: [OK]"
        TEMP_STATUS=0
    fi
else
    # Le dossier n'existe pas, le créer
    mkdir "$TEMP_DIR"
    # Enregistrement des logs
    "$LOG" add DEBUG "│ Dossier temp/ inexistant. Creation dossier temp: [OK]"
    TEMP_STATUS=0
fi

