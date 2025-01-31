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

# Vérification des arguments
if len(sys.argv) != 4:
    print("Usage : python3 generer_html.py <\"nom du livre\"> <fichier_texte> <fichier_sortie>")
    sys.exit(1)

titre = sys.argv[1]
fichier_texte = sys.argv[2]
fichier_sortie = sys.argv[3]

# Lire le fichier texte brut
with open(fichier_texte, "r", encoding="utf-8") as f:
    texte = f.read()

# Fonction pour générer le HTML
def ajouter_balises_html(texte, titre):
    # Ajouter les balises <html>, <head>, <body>
    html_debut = f"""<?xml version='1.0' encoding='utf-8'?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
    <title>{titre}</title>
    <link type="text/css" rel="stylesheet" href="../Styles/style-global.css"/>
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
        texte_html = f"\n      <h1 id=\"toc_1\">{titre}</h1>\n"

        # Ajouter le reste du texte dans des paragraphes <p>
        for ligne in lignes[1:]:
            texte_html += f"\n  <p>{ligne.strip()}</p>\n"
    else:
        texte_html = ""

    # Ajouter les balises HTML de base
    html_complet = html_debut + texte_html + html_fin
    
    # Supprimer les paragraphes vides
    html_complet = re.sub(r"<p>\s*</p>\n", "", html_complet)
    
    return html_complet

# Générer le HTML
texte_html = ajouter_balises_html(texte, titre)

# Sauvegarder dans un fichier de sortie
with open(fichier_sortie, "w", encoding="utf-8") as f:
    f.write(texte_html)

print(f"   Génération HTML Chapitre : OK")
