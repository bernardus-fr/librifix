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

import os
import sys
import json
import subprocess
import time
import re

def log_message(level, message):
    subprocess.run(["./scripts/bash/log_manager.sh", "add", level, message], check=True)

# Chercher une valeur json
def check_json_value(fichier, valeur):
    with open(fichier, "r", encoding="utf-8") as file:
        return json.load(file).get(valeur)

# Rechercher code iso d'une langue
def get_lang_iso_code(language):
    # Fichier de conversion:
    dict_file = "lang/iso_code_lang.json"

    # Normaliser l'entrée (minuscules, suppression des espaces inutiles)
    language = language.strip().lower()

    # Ouverture du dictionnaire:
    with open(dict_file, "r", encoding="utf-8") as file:
        dictionnaire = json.load(file)

    # Parcourir le dictionnaire pour trouver le code ISO correspondant
    for iso_code, names in dictionnaire.items():
        if language in [name.lower() for name in names]:  # Comparaison insensible à la casse
            return iso_code

    return None


    