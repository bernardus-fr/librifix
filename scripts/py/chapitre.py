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
import os

# Vérifier les arguments
if len(sys.argv) != 4:
    print("Usage : python3 chapitre_v1.5.py <chapitre> <notes_modifie> <chapitre_modifie>")
    sys.exit(1)

# Configuration
fichier_chapitre = sys.argv[1]	# Chemin du fichier chapitre de base
chemin_fichier_notes = sys.argv[2]	# Chemin du fichier notes déjà travaillé
fichier_sortie = sys.argv[3]	# Chemin du fichier chapitre fini
id_note_pattern = "nbp{}-{}"  # Identifiant unique des notes
id_texte_pattern = "ntt{}-{}"  # Identifiant unique pour le lien dans le texte

def ajouter_balises_chapitre_avec_doublons(texte, chemin_fichier_notes):
    """
    Ajoute des balises HTML dans le fichier chapitre pour gérer les doublons de notes.
    """
    pattern = r"\((\d{1,2}|1[0-4]\d|150)\)"  # Rechercher les références de notes (numéros entre parenthèses pas plus grand que 150)
    occurences = {}  # Compteur des occurrences pour chaque numéro de note

    def remplacer_note(match):
        num_note = match.group(1)
        # Compter combien de fois cette note est déjà apparue
        occurences[num_note] = occurences.get(num_note, 0) + 1
        suffixe = occurences[num_note]
        
        # Générer les identifiants uniques
        id_note = id_note_pattern.format(num_note, suffixe)
        id_texte = id_texte_pattern.format(num_note, suffixe)
        
        # Extraction du nom de fichier dans le chemin
        nom_fichier_notes = os.path.basename(chemin_fichier_notes)
        
        # Construire la balise HTML
        return f'(<sup><a epub:type="noteref" href="{nom_fichier_notes}#{id_note}" id="{id_texte}">{num_note}</a></sup>)'

    # Remplacer toutes les références avec les balises générées
    texte_modifie = re.sub(pattern, remplacer_note, texte)
    return texte_modifie

# Lecture du fichier
with open(fichier_chapitre, "r", encoding="utf-8") as fichier:
    texte_chapitre = fichier.read()

# Ajout des balises avec gestion des doublons
texte_modifie = ajouter_balises_chapitre_avec_doublons(texte_chapitre, chemin_fichier_notes)

# Écriture dans le fichier
with open(fichier_sortie, "w", encoding="utf-8") as fichier:
    fichier.write(texte_modifie)

print(f"   Traitement du chapitre : OK")
