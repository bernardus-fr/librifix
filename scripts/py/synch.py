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


import re
import sys

# Vérifier les arguments
if len(sys.argv) != 4:
    print("Usage : python3 synch_v1.5.py <chapitre> <notes> <notes_synchro>")
    sys.exit(1)

fichier_chapitre = sys.argv[1]
fichier_notes = sys.argv[2]
fichier_notes_sortie = sys.argv[3]

# Lire les fichiers
with open(fichier_chapitre, "r", encoding="utf-8") as f:
    texte_chapitre = f.read()

with open(fichier_notes, "r", encoding="utf-8") as f:
    texte_notes = f.read()

# Synchronisation
def synchroniser_notes(chapitre, notes):
    pattern_chapitre = r"\((\d{1,2}|1[0-4]\d|150)\)"
    occurrences = {}
    for match in re.findall(pattern_chapitre, chapitre):
        occurrences[match] = occurrences.get(match, 0) + 1

    pattern_notes = r"^(\d+)\)\s*(.*)"
    lignes = notes.splitlines()
    notes_modifiees = []

    for ligne in lignes:
        ligne = ligne.strip()
        match = re.match(pattern_notes, ligne)
        if match:
            num_note = match.group(1)
            texte_note = match.group(2)
            if num_note in occurrences:
                for _ in range(occurrences[num_note]):
                    notes_modifiees.append(f"{num_note}) {texte_note}")
            else:
                notes_modifiees.append(ligne)
        else:
            notes_modifiees.append(ligne)

    return "\n".join(notes_modifiees)

notes_synchronisees = synchroniser_notes(texte_chapitre, texte_notes)

# Sauvegarde
with open(fichier_notes_sortie, "w", encoding="utf-8") as f:
    f.write(notes_synchronisees)

print(f"   Synchronisation : OK")
