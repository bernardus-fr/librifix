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

# Variables
TEMP_DIR="./temp"

# Initialisation des logs
LOG_SCRIPT="./scripts/bash/log_manager.sh" 
"$LOG_SCRIPT" add INFO "Annulation du programme"

# Nettoyage des fichiers temporaires
if [ -d "$TEMP_DIR" ]; then
	rm -r "$TEMP_DIR"
	# Entrée dans les logs
	"$LOG_SCRIPT" add INFO "Suppression des fichiers temporaires: [OK]"
fi

# Fin des logs
"$LOG_SCRIPT" close error

exit 0