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
#  Synchronisation du nombre de notes dans le fichiers de notes pour correspondre exactement
# aux références du chapitre dans le cadre de références multiples: (3) itéré 5 fois dans le
# chapitre dupliquera la note 3) dans le fichiers note pour avoir 5 itérations par exemple.


import re
import sys
from LibFix import utils

# Vérifier les arguments
if len(sys.argv) != 4:
    print("Usage : python3 synch.py <chapitre> <notes> <notes_synchro>")
    sys.exit(1)

fichier_chapitre = sys.argv[1]
fichier_notes = sys.argv[2]
fichier_notes_sortie = sys.argv[3]

# Lire les fichiers
utils.log_message("DEBUG", f"│ Ouverture de {fichier_chapitre} pour synchronisation avec notes")
with open(fichier_chapitre, "r", encoding="utf-8") as f:
    texte_chapitre = f.read()

utils.log_message("DEBUG", f"│ Ouverture de {fichier_notes} pour synchronisation avec chapitre")
with open(fichier_notes, "r", encoding="utf-8") as f:
    texte_notes = f.read()

# Synchronisation
def synchroniser_notes(chapitre, notes):
    pattern_chapitre = r"\((\d{1,2}|1[0-4]\d|150)\)"
    occurrences = {}

    # Trouver toutes les occurrences de chaque note dans le chapitre
    for match in re.findall(pattern_chapitre, chapitre):
        occurrences[match] = occurrences.get(match, 0) + 1

    pattern_notes = r"^(\d+)\)\s*(.*)"
    lignes = notes.splitlines()
    notes_modifiees = []
    
    i = 0
    while i < len(lignes):
        ligne = lignes[i].strip()
        match = re.match(pattern_notes, ligne)

        if match:
            num_note = match.group(1)
            texte_note = match.group(2)
            note_complete = [f"{num_note}) {texte_note}"]

            # Récupérer les paragraphes suivants qui appartiennent à la même note
            i += 1
            while i < len(lignes) and not re.match(pattern_notes, lignes[i]):
                note_complete.append(lignes[i].strip())
                i += 1

            # Si la note est concernée par la duplication, on la répète autant de fois que nécessaire
            if num_note in occurrences:
                for _ in range(occurrences[num_note]):
                    notes_modifiees.extend(note_complete)
            else:
                notes_modifiees.extend(note_complete)

        else:
            notes_modifiees.append(ligne)
            i += 1

    return "\n".join(notes_modifiees)

notes_synchronisees = synchroniser_notes(texte_chapitre, texte_notes)
utils.log_message("DEBUG", f"│ Notes synchronisées pour {fichier_chapitre} et {fichier_notes}")

# Sauvegarde
with open(fichier_notes_sortie, "w", encoding="utf-8") as f:
    f.write(notes_synchronisees)

utils.log_message("DEBUG", f"│ Enregistrement de {fichier_notes_sortie}")
