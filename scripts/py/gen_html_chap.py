#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import re
from pathlib import Path
from bs4 import BeautifulSoup
from LibFix import utils

def is_image_path(line):
    """
    Vérifie si une ligne correspond à un chemin d'image supporté
    Gère aussi le cas avec description (chemin:description)
    """
    line = line.strip()
    if not line:
        return False
    
    # Extensions supportées (ajoutables facilement)
    supported_extensions = ['.jpg', '.jpeg', '.png', '.gif']
    
    # Si la ligne contient ':', vérifier la partie avant les ':'
    if ':' in line:
        potential_path = line.split(':', 1)[0].strip()
    else:
        potential_path = line
    
    # Vérification si le chemin se termine par une extension supportée
    potential_path_lower = potential_path.lower()
    for ext in supported_extensions:
        if potential_path_lower.endswith(ext):
            return True
    
    return False

def validate_image_file(image_path):
    """
    Valide l'existence du fichier image dans le dossier de travail Librifix
    Gère le cas où image_path peut contenir une description
    """
    try:
        # Si la ligne contient ':', extraire seulement le chemin
        if ':' in image_path:
            actual_path = image_path.split(':', 1)[0].strip()
        else:
            actual_path = image_path
            
        # Construction du chemin complet dans le dossier de travail Librifix
        full_path = Path("temp/workdir") / actual_path
        
        if full_path.exists() and full_path.is_file():
            utils.log_message("DEBUG", f"Image trouvée: {full_path}")
            return True
        else:
            utils.log_message("ERROR", f"Fichier image introuvable dans temp/workdir/: {actual_path}")
            return False
    except Exception as e:
        utils.log_message("ERROR", f"Erreur lors de la validation du chemin image {image_path}: {str(e)}")
        return False

def generate_image_html(image_line, image_counter):
    """
    Génère le HTML pour une image avec alternance droite/gauche
    Gère le cas avec ou sans description
    """
    try:
        # Parsing de la ligne pour extraire chemin et description
        if ':' in image_line:
            image_path, description = image_line.split(':', 1)
            image_path = image_path.strip()
            description = description.strip()
        else:
            image_path = image_line.strip()
            description = None
        
        # Extraction du nom de fichier
        filename = Path(image_path).name
        
        # Chemin relatif dans la structure ePub
        epub_image_path = f"../Images/{filename}"
        
        # Alternance droite/gauche basée sur le compteur
        css_class = "image-flottante-d" if image_counter % 2 == 1 else "image-flottante-g"
        
        # Génération de l'alt text et ID unique
        alt_text = f"img{image_counter}"
        
        # Création du HTML avec BeautifulSoup
        div_tag = BeautifulSoup('<div></div>', 'html.parser').div
        div_tag['class'] = css_class
        
        img_tag = BeautifulSoup('<img/>', 'html.parser').img
        img_tag['alt'] = alt_text
        img_tag['class'] = "IDT"
        img_tag['src'] = epub_image_path
        
        div_tag.append(img_tag)
        
        # Ajout de la description si elle existe
        if description:
            p_tag = BeautifulSoup('<p></p>', 'html.parser').p
            p_tag['class'] = "txt-image"
            p_tag.string = description
            div_tag.append(p_tag)
            utils.log_message("INFO", f"Image {filename} ajoutée avec classe {css_class}, chemin {epub_image_path} et description")
        else:
            utils.log_message("INFO", f"Image {filename} ajoutée avec classe {css_class} et chemin {epub_image_path}")
        
        return str(div_tag)
        
    except Exception as e:
        utils.log_message("ERROR", f"Erreur lors de la génération HTML pour l'image {image_line}: {str(e)}")
        return f"<!-- Erreur: Image {image_line} non traitée -->"

def process_chapter_file(book_name, input_file, output_file):
    """
    Traite le fichier chapitre et génère le HTML
    """
    utils.log_message("INFO", f"Début du traitement: {input_file} -> {output_file}")
    
    try:
        # Lecture du fichier source
        with open(input_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        utils.log_message("INFO", f"Fichier lu: {len(lines)} lignes")
        
        # Création de la structure HTML de base
        html_content = """<?xml version='1.0' encoding='utf-8'?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head>
    <meta charset="utf-8"/>
    <title>{}</title>
    <link href="../Styles/style-global.css" rel="stylesheet" type="text/css"/>
</head>
<body>
</body>
</html>""".format(book_name)
        
        soup = BeautifulSoup(html_content, 'html.parser')
        body = soup.find('body')
        
        # Compteurs pour statistiques
        paragraph_count = 0
        image_count = 0
        
        # Traitement ligne par ligne
        for i, line in enumerate(lines):
            line = line.strip()
            
            # Ignorer les lignes vides
            if not line:
                continue
            
            # Première ligne = titre du chapitre
            if i == 0:
                h1_tag = soup.new_tag('h1')
                h1_tag['id'] = "toc_1"
                # Préservation des balises HTML existantes (notes, etc.)
                h1_content = BeautifulSoup(line, 'html.parser')
                h1_tag.append(h1_content)
                body.append(h1_tag)
                utils.log_message("DEBUG", f"Titre du chapitre ajouté avec ID toc_1: {line}")
            
            # Vérification si c'est un chemin d'image
            elif is_image_path(line):
                if validate_image_file(line):
                    image_count += 1
                    image_html = generate_image_html(line, image_count)
                    
                    # Ajout du HTML de l'image
                    image_soup = BeautifulSoup(image_html, 'html.parser')
                    body.append(image_soup)
                    
                    utils.log_message("INFO", f"Image traitée: {line}")
                else:
                    # Ajout d'un commentaire pour image introuvable
                    comment = soup.new_string(f"<!-- Image introuvable: {line} -->")
                    body.append(comment)
                    utils.log_message("WARNING", f"Image ignorée (introuvable): {line}")
            
            # Ligne normale = paragraphe
            else:
                p_tag = soup.new_tag('p')
                # Préservation des balises HTML existantes (notes, etc.)
                p_content = BeautifulSoup(line, 'html.parser')
                p_tag.append(p_content)
                body.append(p_tag)
                paragraph_count += 1
                utils.log_message("DEBUG", f"Paragraphe ajouté: {line[:50]}...")
        
        # Sauvegarde du fichier HTML avec formatage hybride
        with open(output_file, 'w', encoding='utf-8') as f:
            # Formatage manuel pour garder la structure lisible mais préserver les paragraphes
            html_str = str(soup)
            
            # Ajout de retours à la ligne et indentation
            html_str = html_str.replace('</head>', '</head>\n')
            html_str = html_str.replace('<body>', '<body>\n')
            html_str = html_str.replace('<h1', '\n    <h1')
            html_str = html_str.replace('</h1>', '</h1>\n')
            html_str = html_str.replace('<p>', '\n    <p>')
            html_str = html_str.replace('</p>', '</p>\n')
            html_str = html_str.replace('<div', '\n    <div')
            html_str = html_str.replace('</div>', '</div>\n')
            html_str = html_str.replace('</body>', '\n</body>')
            
            f.write(html_str)
        
        utils.log_message("INFO", f"Traitement terminé: {paragraph_count} paragraphes, {image_count} images")
        utils.log_message("INFO", f"Fichier sauvegardé: {output_file}")
        
    except FileNotFoundError:
        utils.log_message("CRITICAL", f"Fichier source introuvable: {input_file}")
        sys.exit(1)
    except Exception as e:
        utils.log_message("CRITICAL", f"Erreur critique lors du traitement: {str(e)}")
        sys.exit(1)

def main():
    """
    Fonction principale du script
    """
    # Validation des arguments
    if len(sys.argv) != 4:
        utils.log_message("ERROR", "Usage: python3 gen_html_chap.py nom_du_livre fichier_chapitre_brut.txt fichier_chapitre_modifié.html")
        sys.exit(1)
    
    book_name = sys.argv[1]
    input_file = sys.argv[2]
    output_file = sys.argv[3]
    
    utils.log_message("INFO", f"Initialisation du script avec: livre='{book_name}', entrée='{input_file}', sortie='{output_file}'")
    
    # Validation de l'existence du fichier d'entrée
    if not os.path.exists(input_file):
        utils.log_message("CRITICAL", f"Fichier d'entrée introuvable: {input_file}")
        sys.exit(1)
    
    # Traitement du fichier
    process_chapter_file(book_name, input_file, output_file)
    
    utils.log_message("INFO", "Script terminé avec succès")

if __name__ == "__main__":
    main()