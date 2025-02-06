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
#  Ajout de toutes les balises html dans le fichiers des notes: entêtes et pieds. Une formatation
# est déjà faite par l'application des notes, on ajoute donc seulement entête et pieds, le reste
# est seulement indenté pour une meilleure lisibilité.


import sys
import re
from LibFix import utils

# Vérification des arguments
if len(sys.argv) != 4:
    print("Usage : python3 gen_html_notes.py <nom_du_livre> <fichier_notes> <fichier_sortie>")
    sys.exit(1)

nom_du_livre = sys.argv[1]
fichier_notes = sys.argv[2]
fichier_sortie = sys.argv[3]

# Lire le fichier texte brut des notes
utils.log_message("DEBUG", f"│ Ouverture de {fichier_notes} pour ajout des balises html")
with open(fichier_notes, "r", encoding="utf-8") as f:
    texte = f.read()

# Fonction pour ajouter les balises HTML
def ajouter_balises_html_notes(texte, nom_du_livre):
    # Ajouter les balises <html>, <head>, <body>
    html_debut = f"""<?xml version='1.0' encoding='utf-8'?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
    <title>{nom_du_livre}</title>
    <link type="text/css" rel="stylesheet" href="../Styles/style-notes.css"/>
</head>
<body>
"""
    html_fin = """
</body>
</html>"""

    # Lire la première ligne
    lignes = texte.strip().splitlines()
    if lignes:
        titre = lignes[0]
        contenu_html = f"\n      <h1>{titre}</h1>\n"

        # Ajouter le reste du texte dans des paragraphes <p>
        for ligne in lignes[1:]:
            contenu_html += f"{ligne.strip()}\n"
    else:
        contenu_html = ""
        
    # Nettoyer le texte
    contenu_html = re.sub(r"<aside", "     <aside", contenu_html)
    contenu_html = re.sub(r"</aside>", "     </aside>", contenu_html)
    contenu_html = re.sub(r"<p>", "  <p>", contenu_html)
        
    # Ajouter les balises HTML de base
    html_complet = html_debut + contenu_html + html_fin
    return html_complet

# Générer le HTML pour les notes
notes_html = ajouter_balises_html_notes(texte, nom_du_livre)
utils.log_message("DEBUG", f"│ Génération des balises html pour {fichier_notes} terminée")

# Sauvegarder dans un fichier de sortie
with open(fichier_sortie, "w", encoding="utf-8") as f:
    f.write(notes_html)

utils.log_message("DEBUG", f"│ Enregistrement de {fichier_sortie} terminée")
