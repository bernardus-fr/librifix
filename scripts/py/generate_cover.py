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
import subprocess

# Gestion des logs
def log_message(level, message):
    subprocess.run(["./scripts/bash/log_manager.sh", "add", level, message], check=True)

def generate_cover_page(image_path):
    """
    Génère une page XHTML de couverture ou de quatrième de couverture en utilisant une image donnée.

    :param image_path: Chemin relatif de l'image (par rapport au dossier OEBPS).
    """
    # Déterminer le type de couverture et les noms des fichiers de sortie
    if "4cover" in image_path.lower():
        xhtml_name = "quatrieme_couverture.xhtml"
        page_title = "Quatrième de couverture"
    else:
        xhtml_name = "page_de_couverture.xhtml"
        page_title = "Couverture"

    # Chemins relatifs des fichiers générés
    output_path = f"temp/epub_temp/OEBPS/Text/{xhtml_name}"
    output_css = f"temp/epub_temp/OEBPS/Styles/style-cover.css"
    css_path = "../Styles/style-cover.css"

    # Contenu de base de la page XHTML
    cover_template = f'''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>{page_title}</title>
    <link rel="stylesheet" href="{css_path}" type="text/css" />
  </head>
  <body>
    <img src="../{image_path}" alt="{page_title}" />
  </body>
</html>
'''

    # Contenu de base du fichier CSS
    style_template = '''@charset "utf-8";
/* Fichier de style pour la couverture */
body {
  margin: 0;
  padding: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  background-color: #fff;
}
img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}
'''

    # Création des répertoires de sortie si nécessaire
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    os.makedirs(os.path.dirname(output_css), exist_ok=True)

    # Écriture du fichier XHTML
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(cover_template)
    log_message("INFO", f"Page de couverture générée avec succès : {output_path}")

    # Écriture du fichier CSS
    with open(output_css, "w", encoding="utf-8") as f:
        f.write(style_template)
    log_message("INFO", f"Page de style générée avec succès : {output_css}")

# Programme principal
def main():
    # Vérifier les arguments
    if len(sys.argv) != 2:
        print("Usage : python3 generate_cover.py <path_to_image>")
        sys.exit(1)
    
    image_path = sys.argv[1]
    
    # Génération de la page de couverture
    generate_cover_page(image_path)

if __name__ == "__main__":
    main()
