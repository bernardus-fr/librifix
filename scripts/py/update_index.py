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
#  Script de mise à jour de l'index: fichiers nav.xhtml et toc.ncx par la réception d'un fichiers
# à la foi, reçu en argument, et qui doit être intégré dans l'ordre de lecture juste.
# Extraction du titre et son ID
# Défénition de l'ordre
# Attention aux namespaces
# Indentation du xml
# Mise à jour des fichiers respectifs toc et nav.


import os
import sys
from xml.etree.ElementTree import ElementTree, Element, SubElement, parse, tostring
import xml.etree.ElementTree as ET
import re
from LibFix import utils

# Configuration des chemins
TOC_FILE = "temp/epub_temp/OEBPS/toc.ncx"
NAV_FILE = "temp/epub_temp/OEBPS/Text/nav.xhtml"
PACKAGE_NS = "http://www.idpf.org/2007/opf"

# Définir l'ordre de tri
order_keys = [
	"page_de_couverture",
	"quatrieme_couverture",
	"page_de_garde",
	"nav",
	"preface",
	"introduction",
	*[f"chapitre{i}" for i in range(1, 100)],  # Gérer jusqu'à chapitre99
	*[f"complement{i}" for i in range(1, 100)]  # Gérer jusqu'à complement99
]

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

# Chargement du fichier et extraction des données
def extract_title_and_id(file_path):
    """Extrait le titre et l'ID d'un fichier XHTML donné."""
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        remove_specific_namespaces(root)

        # Recherche du titre et de l'ID dans la balise <h1>
        h1_element = root.find(".//h1")
        if h1_element is not None:
            title = h1_element.text or "Sans titre"
            file_id = h1_element.get("id")
        else:
            title, file_id = "Sans titre", None

        if not file_id:
            utils.log_message("WARNING", f"│ Aucun ID trouvé dans {file_path}.")
        
        return title, file_id
    except ET.ParseError as e:
        utils.log_message("ERROR", f"│ Erreur de parsing XML dans {file_path} : {e}")
        return None, None

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

def get_sort_key(navpoint):
    src = navpoint.find("content").get("src", "").lower()
    basename = os.path.basename(src).split(".")[0]
    
    if basename in order_keys:
        return (order_keys.index(basename), 0)
    
    #match = re.match(r"(chapitre|complement)(\d+)", basename)
    #if match:
        #return (order_keys.index(match[1]) if match[1] in order_keys else len(order_keys), int(match[2]))
    
    return (len(order_keys) + 1, basename)

def get_sort_key_nav(entry):
    href = entry.find("a").get("href", "").lower()
    basename = os.path.basename(href).split(".")[0]
    
    if basename in order_keys:
        return (order_keys.index(basename), 0)
    
    return (len(order_keys) + 1, basename)

# Mettre à jour le fichier toc
def update_toc(file_name, title_text, file_id):
    """Met à jour le fichier toc.ncx en insérant les entrées triées avec les IDs et playOrder corrects."""
    relative_path = f"Text/{file_name}#{file_id}" if file_id else f"Text/{file_name}"

    if not os.path.exists(TOC_FILE):
        utils.log_message("ERROR", f"│ Le fichier {TOC_FILE} est introuvable.")
        raise FileNotFoundError(f"Le fichier {TOC_FILE} est introuvable.")

    utils.log_message("DEBUG", "│ Mise à jour du fichier toc.ncx commencée.")
    tree = parse(TOC_FILE)
    root = tree.getroot()
    remove_specific_namespaces(root)

    # Vérifier et réinsérer Namespace
    ncx_ns = "http://www.daisy.org/z3986/2005/ncx/"
    if not root.get("xmlns"):
        root.set("xmlns", ncx_ns)

    nav_map = root.find(".//navMap")
    if nav_map is not None:
        existing_navpoints = list(nav_map.findall("navPoint"))
        existing_entry = next((np for np in existing_navpoints if np.find("content").get("src") == relative_path), None)

        if existing_entry is not None:
            existing_entry.find("navLabel/text").text = title_text
        else:
            new_nav_point = ET.Element("navPoint", {"id": "navpoint-temp", "playOrder": "0"})
            nav_label = ET.SubElement(new_nav_point, "navLabel")
            text = ET.SubElement(nav_label, "text")
            text.text = title_text
            ET.SubElement(new_nav_point, "content", {"src": relative_path})
            existing_navpoints.append(new_nav_point)

        existing_navpoints.sort(key=get_sort_key)
        nav_map.clear()
        for idx, np in enumerate(existing_navpoints, start=1):
            np.set("id", f"navpoint-{idx}")
            np.set("playOrder", str(idx))
            nav_map.append(np)
    
    indent_tree(root)
    tree.write(TOC_FILE, encoding="utf-8", xml_declaration=True)
    utils.log_message("DEBUG", f"│ toc.ncx mis à jour avec {file_name}.")

# Mettre à jour le fichier nav.xhtml
def update_nav(file_name, title_text, file_id):
    """Met à jour le fichier nav.xhtml en insérant les entrées triées."""
    if not os.path.exists(NAV_FILE):
        utils.log_message("ERROR", f"│ Le fichier {NAV_FILE} est introuvable.")
        raise FileNotFoundError(f"Le fichier {NAV_FILE} est introuvable.")

    html_ns = "http://www.w3.org/1999/xhtml"
    epub_ns = "http://www.idpf.org/2007/ops"

    utils.log_message("DEBUG", "│ Mise à jour du fichier nav.xhtml commencée.")
    tree = parse(NAV_FILE)
    root = tree.getroot()

    remove_specific_namespaces(root)

    root.set("xmlns", html_ns)
    root.set("xmlns:epub", epub_ns)

    nav_list = root.find(".//ol")
    
    if nav_list is not None:
        href = f"{file_name}#{file_id}" if file_id else f"{file_name}"
        existing_entries = {entry.find("a").get("href", ""): entry for entry in nav_list.findall("li")}

        if href in existing_entries:
			# Mettre à jour le titre de l'entrée existante
            existing_entries[href].find("a").text = title_text
        else:
            # Ajouter une nouvelle entrée
            new_entry = ET.Element("li", {"class": "rang1"})
            new_link = ET.SubElement(new_entry, "a", {"href": href})
            new_link.text = title_text
            nav_list.append(new_entry)

        # Trier les entrées
        sorted_entries = sorted(nav_list.findall("li"), key=get_sort_key_nav)
        nav_list.clear()
        for entry in sorted_entries:
            nav_list.append(entry)

    for nav in root.iter('nav'):
        # Construire le nom de l'attribut avec l'URI complet
        attr_name = 'epub:type'
    
        # Ajouter l'attribut 'type' avec la valeur souhaitée
        nav.set(attr_name, "toc")
        
    indent_tree(root)
    tree.write(NAV_FILE, encoding="utf-8", xml_declaration=True)
    utils.log_message("DEBUG", f"│ nav.xhtml mis à jour avec {file_name}.")

# Script principal
def main():
    if len(sys.argv) != 2:
        utils.log_message("ERROR", "│ Usage: python update_index.py <file_name>")
        sys.exit(1)

    file_name = sys.argv[1]
    file_path = os.path.join("temp/epub_temp/OEBPS/Text", file_name)
    basename = os.path.basename(file_name).split(".")[0]
    file_id = None

    if not os.path.exists(file_path):
        utils.log_message("ERROR", f"│ Fichier introuvable : {file_path}")
        sys.exit(1)

    if basename == "page_de_couverture":
    	title_text = "Couverture"
    elif basename == "quatrieme_couverture":
    	title_text = "Quatrième de Couverture"
    elif basename == "page_de_garde":
    	title_text = "Page de Garde"
    elif basename == "nav":
    	title_text = "Table des Matières"
    elif basename == "preface":
    	title_text = "Préface"
    elif basename == "introduction":
    	title_text = "Introduction"
    else:
    	title_text, file_id = extract_title_and_id(file_path)

    if title_text:
        update_toc(file_name, title_text, file_id)
        update_nav(file_name, title_text, file_id)
    else:
        utils.log_message("WARNING", f"│ Impossible d'extraire les données pour {file_name}.")

if __name__ == "__main__":
    main()
