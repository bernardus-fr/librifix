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
#  Formatation de chaque texte de note du fichier de note, en ajoutant le lien au numéro de
# note dans le chapitre correspondant. Gère les références multiples avec un indice dans l'ID
# de la balise


import re
import sys
import os
from LibFix import utils

# Vérifier les arguments
if len(sys.argv) != 4:
    print("Usage : python3 notes_v1.5.py <notes_synchro> <chapitre> <notes_modifie>")
    sys.exit(1)

# Fichiers d'entrée et de sortie
fichier_notes = sys.argv[1]
fichier_chapitre = sys.argv[2]
fichier_sortie = sys.argv[3]

utils.log_message("DEBUG", f"│ Ouverture de {fichier_notes} mettre en forme les notes")
# Lire le fichier source
with open(fichier_notes, "r", encoding="utf-8") as f:
    notes = f.read()

def ajouter_aside_et_paragraphes(notes, fichier_chapitre):

    # Dictionnaire pour gérer les occurrences multiples des notes
    occurences = {}

    def generer_aside(match):
        numero = match.group(1)  # Numéro de la note
        texte_note = match.group(2)  # Texte de la note

        # Gestion des occurrences multiples
        occurences[numero] = occurences.get(numero, 0) + 1
        suffixe = occurences[numero]

        # Ajouter un suffixe à chaque identifiant pour gérer les références multiples
        id_note = f"nbp{numero}-{suffixe}"
        id_ref = f"ntt{numero}-{suffixe}"
        
        # Extraction du nom de fichier dans le chemin
        nom_fichier_chapitre = os.path.basename(fichier_chapitre)

        # Diviser le texte en paragraphes
        paragraphs = [p.strip() for p in texte_note.split("\n") if p.strip()]
        html_note = f'<aside epub:type="footnote" id="{id_note}">\n'
        for i, para in enumerate(paragraphs):
            if i == 0:
                html_note += f'<p><a epub:type="noteref" href="{nom_fichier_chapitre}#{id_ref}">{numero})</a> {para}</p>\n'
            else:
                html_note += f'<p>{para}</p>\n'
        html_note += f'  </aside>\n'
        return html_note

    # Rechercher et transformer les notes
    pattern = r"(\d{1,2})\) (.+?)(?=(?:\n\d{1,2}\) |\Z))"
    notes_modifiees = re.sub(pattern, generer_aside, notes, flags=re.S)

    return notes_modifiees

# Appliquer la fonction
notes_modifiees = ajouter_aside_et_paragraphes(notes, fichier_chapitre)
utils.log_message("DEBUG", f"│ Notes misent en formme pour {fichier_notes}")

# Sauvegarder le fichier modifié
with open(fichier_sortie, "w", encoding="utf-8") as f:
    f.write(notes_modifiees)

utils.log_message("DEBUG", f"│ Enregistrement de {fichier_sortie}")
