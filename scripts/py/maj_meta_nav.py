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
#  Script de mise à jour de l'index: fichiers nav.xhtml avec les simples métadonnées reçues
# de l'utilisateur, spécialement la langue


import os
import sys
from xml.etree.ElementTree import ElementTree, Element, SubElement, parse, tostring
import xml.etree.ElementTree as ET
import re
from LibFix import utils

# Configuration des chemins
NAV_FILE = "temp/epub_temp/OEBPS/Text/nav.xhtml"
PACKAGE_NS = "http://www.idpf.org/2007/opf"
METADATA_JSON = "temp/metadata.json"



# Enlever les namespaces indésirables
def remove_specific_namespaces(elem):
    html_ns = "http://www.w3.org/1999/xhtml"
    dc_ns = "http://purl.org/dc/elements/1.1/"
    epub_ns = "http://www.idpf.org/2007/ops"

    for el in elem.iter():
        if el.tag.startswith("{"):
            uri, tag = el.tag[1:].split("}", 1)
            if uri == dc_ns:
                el.tag = f"dc:{tag}"  # Conserver le préfixe dc:
            elif uri == html_ns:
                el.tag = tag
            elif uri == epub_ns:
            	el.tag = f"epub:{tag}"
            else:
                el.tag = tag  # Supprimer les autres préfixes

        # Traiter les namespaces des attributs
        for attr, value in list(el.attrib.items()):
            if "{" in attr:  # Si l'attribut contient un namespace
                uri, attr_name = attr[1:].split("}", 1)
                if uri == dc_ns:
                    el.attrib[attr_name] = f"dc:{attr_name}"  # Conserver le préfixe dc:
                elif uri == html_ns:
                    el.attrib[attr_name] = value  # Supprimer le namespace html
                elif uri == epub_ns:
                	del el.attrib[attr]
                else:
                    el.attrib[attr_name] = value  # Supprimer les autres préfixes

# Ajout de l'indentation pour le formatage XML
def indent_tree(elem, level=0):
    i = "\n" + level * "  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        for child in elem:
            indent_tree(child, level + 1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i


# Mettre à jour le fichier nav.xhtml
def main():
    """Met à jour le fichier nav.xhtml en insérant les entrées triées."""
    if not os.path.exists(NAV_FILE):
        utils.log_message("ERROR", f"│ Le fichier {NAV_FILE} est introuvable.")
        raise FileNotFoundError(f"Le fichier {NAV_FILE} est introuvable.")

    # Rechercher la langue de l'epub
    langue = utils.check_json_value(METADATA_JSON, "language")
    fichier_langue = f"lang/struct_epub/{langue}.json"

    html_ns = "http://www.w3.org/1999/xhtml"
    epub_ns = "http://www.idpf.org/2007/ops"

    utils.log_message("DEBUG", "│ Mise à jour du fichier nav.xhtml commencée.")
    tree = parse(NAV_FILE)
    root = tree.getroot()

    remove_specific_namespaces(root)

    root.set("xmlns", html_ns)
    root.set("xmlns:epub", epub_ns)

    titre = root.find(".//h1")
    titre.text = utils.check_json_value(fichier_langue, "table_of_contents")
    utils.log_message("DEBUG", f"Titre mis à jours dans le nav avec la langue {langue}")

    for nav_list in root.findall(".//li"):
        lien = nav_list.find(".//a")
        lien.text = utils.check_json_value(fichier_langue, lien.text)

    utils.log_message("DEBUG", "Entrées mis à jours dans le nav pour garde et index")

    for nav in root.iter('nav'):
        # Construire le nom de l'attribut avec l'URI complet
        attr_name = 'epub:type'
    
        # Ajouter l'attribut 'type' avec la valeur souhaitée
        nav.set(attr_name, "toc")
        
    indent_tree(root)
    tree.write(NAV_FILE, encoding="utf-8", xml_declaration=True)
    utils.log_message("DEBUG", f"│ nav.xhtml mis à jour avec les langues.")


if __name__ == "__main__":
    main()
