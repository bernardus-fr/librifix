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
#  Mise à jour des métadonnées dans le fichiers content.opf, récupérées dans le metadata.json
# contenant les données de l'utilisateur. Ce script ne fait que préparer l'archive sans inclure
# quelque fichiers que ce soit. Une version ultérieure fera peut-être la fusion avec le update_manifest.py


import os
import json
from xml.etree.ElementTree import ElementTree, Element, SubElement, parse, tostring
from datetime import datetime, timezone
from LibFix import utils

# Chemins des fichiers
metadata_file = "temp/metadata.json"
language_codes_file = "utils/language_codes.json"
content_opf_file = "temp/epub_temp/OEBPS/content.opf"

# Chargement des métadonnées
def load_metadata():
    if not os.path.exists(metadata_file):
        utils.log_message("ERROR", f"│ Le fichier {metadata_file} est introuvable.")
        raise FileNotFoundError(f"Le fichier {metadata_file} est introuvable.")

    with open(metadata_file, "r", encoding="utf-8") as f:
        metadata = json.load(f)

    # Vérification des champs obligatoires
    for field in ["title", "creator", "language"]:
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

# Suppression des préfixes ns0 et ns1 tout en conservant dc:
def remove_ns_prefixes(elem):
    for el in elem.iter():
        if el.tag.startswith("{"):
            uri, tag = el.tag[1:].split("}", 1)
            if uri == "http://purl.org/dc/elements/1.1/":
                el.tag = f"dc:{tag}"  # Conserver le préfixe dc:
            else:
                el.tag = tag  # Supprimer les autres préfixes

# Obtenir la date et l'heure actuelles au format ISO 8601
def get_current_iso8601():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    # return datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

# Mise à jour du fichier content.opf
def update_content_opf(metadata, language_map):
    if not os.path.exists(content_opf_file):
        utils.log_message("ERROR", f"│ Le fichier {content_opf_file} est introuvable.")
        raise FileNotFoundError(f"Le fichier {content_opf_file} est introuvable.")

    utils.log_message("DEBUG", "│ Mise à jour du fichier content.opf commencée.")
    tree = parse(content_opf_file)
    root = tree.getroot()

    # Gestion des namespaces
    package_ns = "http://www.idpf.org/2007/opf"
    dc_ns = "http://purl.org/dc/elements/1.1/"

    # Ajouter xmlns global dans <package>
    root.attrib["xmlns"] = package_ns

    # Trouver la section <metadata>, et s'il y en a plusieurs, en garder une seule
    metadata_elems = root.findall(f".//{{{package_ns}}}metadata")
    if len(metadata_elems) > 1:
        # Conserver uniquement la première
        for extra_metadata in metadata_elems[1:]:
            root.remove(extra_metadata)

    metadata_elem = metadata_elems[0] if metadata_elems else SubElement(root, "metadata")
    metadata_elem.attrib["xmlns:dc"] = dc_ns
    metadata_elem.attrib["xmlns:opf"] = package_ns

    def update_or_create(tag, value):
        elem = metadata_elem.find(f".//{{{dc_ns}}}{tag}")
        if elem is None:
            elem = SubElement(metadata_elem, f"{{{dc_ns}}}{tag}")
        elem.text = value

    # Mise à jour des métadonnées obligatoires
    update_or_create("title", metadata["title"])
    utils.log_message("DEBUG", f"│ Titre ajouté: {metadata["title"]}")

    update_or_create("creator", metadata["creator"])
    utils.log_message("DEBUG", f"│ Auteur ajouté: {metadata["creator"]}")

    language_code = get_language_code(metadata["language"], language_map)
    update_or_create("language", language_code)
    utils.log_message("DEBUG", f"│ Lange ajoutée: {metadata["language"]}")

    # Mise à jour de la balise dcterms:modified
    current_time = get_current_iso8601()
    dcterms_modified = metadata_elem.find(".//meta[@property='dcterms:modified']")
    if dcterms_modified is None:
        dcterms_modified = SubElement(metadata_elem, "meta", {"property": "dcterms:modified"})
    dcterms_modified.text = current_time
    utils.log_message("DEBUG", f"│ Date ajoutée {current_time}")

    # Mise à jour des champs optionnels
    optional_fields = {
        "identifier": "identifier",
        "date": "date",
        "publisher": "publisher",
        "contributor": "contributor",
        "subject": "subject",
        "source": "source",
        "rights": "rights",
        "description": "description"
    }

    for meta_key, opf_tag in optional_fields.items():
        if metadata.get(meta_key):
            update_or_create(opf_tag, metadata[meta_key])
    utils.log_message("DEBUG", "│ Ajout des champs facultatifs")

    # Supprimer les préfixes ns0 et ns1
    remove_ns_prefixes(root)

    # Ajouter l'indentation pour le fichier OPF
    indent_tree(root)

    # Écriture des modifications
    utils.log_message("DEBUG", "│ Écriture des données")
    tree.write(content_opf_file, encoding="utf-8", xml_declaration=True)
    utils.log_message("DEBUG", "│ Mise à jour du fichier content.opf terminée avec succès.")


# Programme principal
def main():
    try:
        utils.log_message("DEBUG", "│ Début de la mise à jour des métadonnées EPUB.")
        metadata = load_metadata()
        language_map = load_language_codes()
        update_content_opf(metadata, language_map)
        utils.log_message("DEBUG", "│ Mise à jour des métadonnées terminée avec succès.")
    except Exception as e:
        utils.log_message("ERROR", f"│ Erreur : {e}")
        print(f"Erreur : {e}")

if __name__ == "__main__":
    main()
