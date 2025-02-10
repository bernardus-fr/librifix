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
#  Simple mise à jour du fichiers toc.ncx avec les données entrées par l'utilisateur et conservées
# dans les metadata.json. Une version ultérieure fera peut-être la fusion avec le update_index.py


import os
import json
from xml.etree.ElementTree import ElementTree, Element, SubElement, parse, tostring
from datetime import datetime, timezone
from LibFix import utils

# Chemins des fichiers
metadata_file = "temp/metadata.json"
language_codes_file = "utils/language_codes.json"
toc_ncx_file = "temp/epub_temp/OEBPS/toc.ncx"

# Chargement des métadonnées
def load_metadata():
    if not os.path.exists(metadata_file):
        utils.log_message("ERROR", f"│ Le fichier {metadata_file} est introuvable.")
        raise FileNotFoundError(f"Le fichier {metadata_file} est introuvable.")

    with open(metadata_file, "r", encoding="utf-8") as f:
        metadata = json.load(f)

    # Vérification des champs obligatoires
    for field in ["title", "language", "identifier"]:
        if field not in metadata or not metadata[field].strip():
            utils.log_message("ERROR", f"│ Le champ obligatoire '{field}' est manquant ou vide dans les métadonnées.")
            raise ValueError(f"Le champ obligatoire '{field}' est manquant ou vide dans les métadonnées.")

    utils.log_message("DEBUG", "│ Méta-données chargées avec succès.")
    return metadata

# Chargement de la correspondance des codes de langue
def load_language_codes():
    if not os.path.exists(language_codes_file):
        utils.log_message("ERROR", f"│ Le fichier {language_codes_file} est introuvable.")
        raise FileNotFoundError(f"Le fichier {language_codes_file} est introuvable.")

    with open(language_codes_file, "r", encoding="utf-8") as f:
        language_map = json.load(f)

    utils.log_message("DEBUG", "│ Fichier de codes de langues chargé avec succès.")
    return language_map

# Conversion du nom de la langue en code ISO
def get_language_code(language_name, language_map):
    language_name_lower = language_name.strip().lower()
    return language_map.get(language_name_lower, language_name_lower)

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

# Suppression des préfixes des espaces de noms
def remove_namespace_prefixes(elem):
    # Vérification si l'élément est le racine (et doit conserver le namespace xmlns)
    if elem.tag.startswith("{"):
        uri, tag = elem.tag[1:].split("}", 1)
        if uri == "http://www.daisy.org/z3986/2005/ncx/":
            elem.tag = tag
            elem.set("xmlns", uri)  # Assure que l'attribut xmlns est conservé pour l'élément racine
        else:
            elem.tag = tag

    # Parcours des sous-éléments et suppression des préfixes de namespace
    for el in elem.iter():
        if el.tag.startswith("{"):
            uri, tag = el.tag[1:].split("}", 1)
            if uri == "http://www.daisy.org/z3986/2005/ncx/":
                el.tag = tag
            else:
                el.tag = tag

# Obtenir la date et l'heure actuelles au format ISO 8601
def get_current_iso8601():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# Mise à jour du fichier toc.ncx
def update_toc_ncx(metadata, language_map):
    if not os.path.exists(toc_ncx_file):
        utils.log_message("ERROR", f"│ Le fichier {toc_ncx_file} est introuvable.")
        raise FileNotFoundError(f"Le fichier {toc_ncx_file} est introuvable.")

    # Rechercher la langue de l'epub
    fichier_langue = f"lang/struct_epub/{metadata["language"]}.json"

    utils.log_message("DEBUG", "│ Mise à jour du fichier toc.ncx commencée.")
    tree = parse(toc_ncx_file)
    root = tree.getroot()

    # Namespace
    ncx_ns = "http://www.daisy.org/z3986/2005/ncx/"

    # Mise à jour de l'attribut xml:lang
    #language_code = get_language_code(metadata["language"], language_map)
    root.set("{http://www.w3.org/XML/1998/namespace}lang", metadata["language"])
    utils.log_message("DEBUG", f"│ Langue ajoutée: {metadata["language"]}")

    # Mise à jour de l'identifiant dans <meta name="dtb:uid">
    meta_uid_elem = root.find(f".//{{{ncx_ns}}}meta[@name='dtb:uid']")
    if meta_uid_elem is None:
        meta_uid_elem = SubElement(root, f"{{{ncx_ns}}}meta", {"name": "dtb:uid"})
    meta_uid_elem.attrib["content"] = metadata["identifier"]
    utils.log_message("DEBUG", f"│ Identifiant ajouté: {metadata["identifier"]}")

    # Mise à jour du titre dans <docTitle>
    doc_title_elem = root.find(f".//{{{ncx_ns}}}docTitle")
    if doc_title_elem is None:
        doc_title_elem = SubElement(root, f"{{{ncx_ns}}}docTitle")
    text_elem = doc_title_elem.find(f".//{{{ncx_ns}}}text")
    if text_elem is None:
        text_elem = SubElement(doc_title_elem, f"{{{ncx_ns}}}text")
    text_elem.text = metadata["title"]
    utils.log_message("DEBUG", f"│ Titre ajouté: {metadata["title"]}")

    for text in root.findall(f".//{{{ncx_ns}}}text"):
        text.text = utils.check_json_value(fichier_langue, text.text)

    # Supprimer les préfixes des espaces de noms
    remove_namespace_prefixes(root)

    # Ajouter l'indentation pour le fichier NCX
    indent_tree(root)

    # Écriture des modifications
    utils.log_message("DEBUG", f"│ Écriture du fichier {toc_ncx_file}")
    tree.write(toc_ncx_file, encoding="utf-8", xml_declaration=True)
    

# Programme principal
def main():
    try:
        utils.log_message("DEBUG", "│ Début de la mise à jour du fichier toc.ncx.")
        metadata = load_metadata()
        language_map = load_language_codes()
        update_toc_ncx(metadata, language_map)
        utils.log_message("DEBUG", "│ Mise à jour du fichier toc.ncx terminée avec succès.")
    except Exception as e:
        utils.log_message("ERROR", f"│ Erreur : {e}")
        print(f"Erreur : {e}")

if __name__ == "__main__":
    main()
