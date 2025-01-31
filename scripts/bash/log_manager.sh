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


# Configuration du répertoire des logs
LOG_DIR="logs"
ERROR_DIR="${LOG_DIR}/errors"
CURRENT_LOG="${LOG_DIR}/current.log"

# Couleurs pour la coloration syntaxique
RESET="\033[0m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
GREEN="\033[32m"
CYAN="\033[36m"

# Fonction pour initialiser le répertoire des logs
initialize_log_dirs() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$ERROR_DIR"
}

# Fonction pour créer un nouveau log
create_log() {
    if [ -f "$CURRENT_LOG" ]; then
        echo -e "${RED}Un log est déjà en cours. Veuillez le fermer avant d'en créer un nouveau.${RESET}"
        exit 1
    fi

    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "Log démarré à $timestamp" > "$CURRENT_LOG"
    echo -e "${GREEN}Nouveau log créé : $CURRENT_LOG${RESET}"
}

# Fonction pour ajouter un message au log
add_log() {
    if [ ! -f "$CURRENT_LOG" ]; then
        echo -e "${RED}Aucun log actif. Veuillez créer un log d'abord.${RESET}"
        exit 1
    fi

    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    case "$level" in
        DEBUG) color="$CYAN" ;;
        INFO) color="$BLUE" ;;
        WARNING) color="$YELLOW" ;;
        ERROR|CRITICAL) color="$RED" ;;
        *) color="$RESET" ; level="INFO" ;;
    esac

    echo "[$timestamp] [$level] $message" >> "$CURRENT_LOG"
    echo -e "${color}[$timestamp] [$level] $message${RESET}"
}

# Fonction pour fermer le log
close_log() {
    if [ ! -f "$CURRENT_LOG" ]; then
        echo -e "${RED}Aucun log actif à fermer.${RESET}"
        exit 1
    fi

    local status="$1"
    local timestamp=$(date "+%Y%m%d_%H%M%S")

    if [ "$status" == "error" ]; then
        local new_log="${ERROR_DIR}/error_${timestamp}.log"
        mv "$CURRENT_LOG" "$new_log"
        echo -e "${RED}Log fermé avec des erreurs : $new_log${RESET}"
    else
        local new_log="${LOG_DIR}/log_${timestamp}.log"
        mv "$CURRENT_LOG" "$new_log"
        echo -e "${GREEN}Log fermé : $new_log${RESET}"
    fi
}

# Gestion des commandes
initialize_log_dirs

case "$1" in
    create)
        create_log
        ;;
    add)
        add_log "$2" "$3"
        ;;
    close)
        close_log "$2"
        ;;
    *)
        echo -e "${YELLOW}Usage : $0 {create|add <LEVEL> <MESSAGE>|close [error]}${RESET}"
        exit 1
        ;;
esac
