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
#  Sortie correcte du programme en terminant les logs et nettoyant les fichiers temporaires
# tant en cas d'erreur que d'annulation.


# Définition des Variables d'environnement:
source scripts/bash/utils.sh

# Variables
STATUS="$1"

# Fonctio de mise à jour du status d'exit dans le config.ini
update_last_exit_status() {
    local status="$1"  # Récupère le statut passé en argument (ex: "success" ou "error")

    # Vérifie que le fichier config.ini existe
    if [[ ! -f "$CONFIG_FILE" ]]; then
        "$LOG" add ERROR "Fichier de configuration introuvable : $CONFIG_FILE"
        exit 1
    fi

    # Vérifie si la section [General] existe, sinon l'ajoute
    if ! grep -q "^\[General\]" "$CONFIG_FILE"; then
        echo -e "\n[General]" >> "$CONFIG_FILE"
    fi

    # Met à jour ou ajoute la valeur last_exit
    if grep -q "^last_exit=" "$CONFIG_FILE"; then
        sed -i "s|^last_exit=.*|last_exit=$status|" "$CONFIG_FILE"
    else
        echo "last_exit=$status" >> "$CONFIG_FILE"
    fi

    "$LOG" add DEBUG "Dernier état du programme enregistré : $status"
}

# Initialisation des logs
"$LOG" add DEBUG "Annulation du programme"

# Nettoyage des fichiers temporaires
if [ -d "$TEMP_DIR" ]; then
	rm -r "$TEMP_DIR"
	# Entrée dans les logs
	"$LOG" add DEBUG "Suppression des fichiers temporaires: [OK]"
fi

# Fin des logs

if [[ "$STATUS" == "error" ]]; then
    update_last_exit_status "error"
    "$LOG" close error
elif [[ "$STATUS" == "annulation" ]]; then
    update_last_exit_status "cancel"
    "$LOG" close
elif [[ "$STATUS" == "success" ]]; then
    update_last_exit_status "success"
    "$LOG" close
else
    echo "Mauvais usage du script. Utilisation : $0 {error|annulation|success}"
    exit 1
fi

exit 0