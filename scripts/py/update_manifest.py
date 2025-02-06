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
#  Script de mise à jour du <manifest> et <spine> (ordre de lecture) du fichiers conten.opf
# par la réceptions des fichiers un par un donnés comme argument.
# Ordre des fichiers
# Fonction de chaque fichiers
# Où l'intégrer
# Namespaces
# Indentation ...


import os
import json
import time
from xml.etree.ElementTree import ElementTree, Element, SubElement, parse, tostring
import xml.etree.ElementTree as ET
from LibFix import utils

# Chemins des fichiers
content_opf_file = "temp/epub_temp/OEBPS/content.opf"

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

# Suppression des préfixes ns0 et ns1 tout en conservant dc:
def remove_ns_prefixes(elem):
    for el in elem.iter():
        if el.tag.startswith("{"):
            uri, tag = el.tag[1:].split("}", 1)
            if uri == "http://purl.org/dc/elements/1.1/":
                el.tag = f"dc:{tag}"  # Conserver le préfixe dc:
            else:
                el.tag = tag  # Supprimer les autres préfixes

# Tri des éléments du spine selon SPINE_ORDER
def sort_spine(spine,):
    SPINE_ORDER = [
        "page_de_couverture",
        "quatrieme_couverture",
        "garde",
        "nav",
        "preface",
        "introduction",
        *[f"chapitre{i}" for i in range(1, 100)],  # Gérer jusqu'à chapitre99
        *[f"complement{i}" for i in range(1, 100)],  # Gérer jusqu'à complement99
        "notes_preface",
        "notes_introduction",
        *[f"notes_chapitre{i}" for i in range(1, 100)],
        *[f"notes_complement{i}" for i in range(1, 100)]
    ]

    def spine_sort_key(item):
        idref = item.attrib.get("idref", "")
        if idref in SPINE_ORDER:
            return (SPINE_ORDER.index(idref), idref)
        # Placer les éléments non trouvés dans SPINE_ORDER après les autres, triés alphabétiquement
        return (len(SPINE_ORDER), idref)

    items = list(spine.findall("itemref"))
    sorted_items = sorted(items, key=spine_sort_key)

    # Supprimer les éléments existants du spine
    for item in items:
        spine.remove(item)

    # Réinsérer les éléments triés
    for item in sorted_items:
        spine.append(item)

# Mise à jour du manifest et du spine dans content.opf
def update_manifest_and_spine(file_path):
    if not os.path.exists(content_opf_file):
        utils.log_message("ERROR", f"│ Le fichier {content_opf_file} est introuvable.")
        raise FileNotFoundError(f"Le fichier {content_opf_file} est introuvable.")

    utils.log_message("DEBUG", "│ Mise à jour du manifest et du spine commencée.")
    tree = parse(content_opf_file)
    root = tree.getroot()

    # Gestion des namespaces
    package_ns = "http://www.idpf.org/2007/opf"
    dc_ns = "http://purl.org/dc/elements/1.1/"

    # Ajouter xmlns global dans <package>
    root.attrib["xmlns"] = package_ns

    # Trouver la section <metadata>, et s'il y en a plusieurs, en garder une seule
    metadata_elems = root.findall(f".//{{{package_ns}}}metadata")

    # Ajouter xmlns:dc :opf dans la section metadata
    metadata_elem = metadata_elems[0] if metadata_elems else SubElement(root, "metadata")
    metadata_elem.attrib["xmlns:dc"] = dc_ns
    metadata_elem.attrib["xmlns:opf"] = package_ns

    # Ajouter xmlns global dans <package>
    root.attrib["xmlns"] = package_ns

    # Trouver les sections <manifest> <spine> <guide>
    manifest = root.find(f".//{{{package_ns}}}manifest")
    spine = root.find(f".//{{{package_ns}}}spine")
    guide = root.find(f".//{{{package_ns}}}guide")

    if manifest is None:
        manifest = SubElement(root, "manifest")
    if spine is None:
        spine = SubElement(root, "spine")

    # Obtenir le nom du fichier et son extension
    file_name = os.path.basename(file_path)
    file_ext = os.path.splitext(file_name)[1].lower()

    # Identifier le type de fichier et préparer les attributs
    media_type_map = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".gif": "image/gif",
        ".svg": "image/svg+xml",
        ".xhtml": "application/xhtml+xml",
        ".css": "text/css",
        ".ttf": "application/font-sfnt",
        ".otf": "application/font-sfnt"
    }
    media_type = media_type_map.get(file_ext)

    if not media_type:
        utils.log_message("ERROR", f"│ Type de fichier non reconnu pour {file_name}.")
        raise ValueError(f"Type de fichier non reconnu pour {file_name}.")
        # Améliorer ici en ignorant le fichiers s'il n'est pas reconnu

    utils.log_message("DEBUG", f"│ Fichier détecté : {file_name} (type {media_type})")

    # Vérifier si le fichier est déjà dans le manifest
    existing_item = manifest.find(f".//{{{package_ns}}}item[@href='{file_path}']")
    if existing_item is not None:
        utils.log_message("INFO", f"│ Le fichier {file_name} est déjà présent dans <manifest>.")
    else:
        utils.log_message("DEBUG", f"│ {file_path} non trouvé dans <manifest>. Ajout du fichier.")
        item_id = os.path.splitext(file_name)[0]
        if item_id == "4cover":
            item_id = "cover4"
        SubElement(manifest, "item", {
            "id": item_id,
            "href": file_path,
            "media-type": media_type
        })
        utils.log_message("DEBUG", f"│ Fichier ajouté à <manifest> : {file_name}")

        # Image de couverture
        if item_id == "cover":
            # Ajout aux métadonnées
            existing_cover_meta = metadata_elem.find(".//meta[@name='cover']")
            if existing_cover_meta is None:
                existing_cover_meta = SubElement(metadata_elem, "meta", {"name": "cover", "content": file_path})
                utils.log_message("DEBUG", f"│ Couverture ajouté à la section <metadata>: {file_path}")
            else:
                utils.log_message("INFO", f"│ Le fichier {file_name} est déjà présent dans <metadata>.")

        # Page de couverture
        if item_id == "page_de_couverture":
            existing_cover_guide = guide.find(f".//{{{package_ns}}}reference[@type='cover']")
            if existing_cover_guide is None:
                existing_cover_guide = SubElement(guide, "reference", {
                    "type": "cover",
                    "title": "Couverture",
                    "href": file_path,
                    "property": "coverpage",
                })
                utils.log_message("DEBUG", f"│ Couverture ajoutée à la section <guide>: {file_path}")
            else:
                # Mise à jour de guide
                utils.log_message("INFO", f"│ Couverture déjà présent dans <guide> - modification")
                existing_cover_guide.set("type", "cover")
                existing_cover_guide.set("title", "Couverture")
                existing_cover_guide.set("href", file_path)
                utils.log_message("DEBUG", f"│ Couverture mise à jour dans la section <guide>: {file_path}")

        # Ajouter au spine si nécessaire
        if media_type == "application/xhtml+xml" and file_name != "toc.xhtml":
            existing_spine_item = spine.find(f".//{{{package_ns}}}itemref[@idref='{item_id}']")
            if existing_spine_item is not None:
                utils.log_message("INFO", f"│ Le fichier {file_name} est déjà présent dans le spine.")
            else:
                SubElement(spine, "itemref", {"idref": item_id})
                utils.log_message("DEBUG", f"│ Fichier ajouté au spine : {file_name}")
        else:
            utils.log_message("DEBUG", f"│ Le fichier {file_name} n'a pas été ajouté au spine (non éligible).")
                

    # Supprimer les préfixes ns0 et ns1
    remove_ns_prefixes(root)

    # Trier les éléments du spine
    sort_spine(spine)

    # Ajouter l'indentation pour le fichier OPF
    indent_tree(root)

    # Écriture des modifications
    utils.log_message("DEBUG", "│ Écriture des données dans content.opf")
    tree.write(content_opf_file, encoding="utf-8", xml_declaration=True)
    utils.log_message("DEBUG", "│ Mise à jour du manifest et du spine terminée avec succès.")

# Programme principal
def main():
    try:
        import sys
        if len(sys.argv) != 2:
            utils.log_message("ERROR", "│ Usage : python3 update_manifest.py <chemin_du_fichier>")
            return

        file_path = sys.argv[1]
        utils.log_message("DEBUG", f"│ Début de la mise à jour pour {file_path}.")
        update_manifest_and_spine(file_path)
        utils.log_message("DEBUG", "│ Mise à jour terminée avec succès.")
    except Exception as e:
        utils.log_message("ERROR", f"│ Erreur : {e}")
        print(f"Erreur : {e}")

if __name__ == "__main__":
    main()
