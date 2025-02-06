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
    "$LOG" close error
elif [[ "$STATUS" == "annulation" ]]; then
    "$LOG" close
else
    echo "Mauvais usage du script. Utilisation : $0 {error|annulation}"
    exit 1
fi

exit 0