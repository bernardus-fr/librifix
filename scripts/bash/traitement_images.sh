#!/bin/bash

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
#  Script du traitement des fichiers images: traite la taille et le poid si nécessaire,
# déplacement dans la structure epub temporaire, et mise à jour du content.opf. Si l'image
# est la couverture ou le quatrième de couverture, génération des fichires xhtml relatifs.
# Utilisation: ./traitement_images.sh <fichier>


# Définition des Variables d'environnement:
#source scripts/bash/utils.sh
source scripts/bash/utils_variables.sh
source scripts/bash/utils_fonctions.sh

"$LOG" add DEBUG "│ Démarrage du traitement des images."

# Récupérer le fichier image en argument système
if [ "$#" -ne 1 ]; then
    "$LOG" add ERROR "│ Usage : $0 <nom_du_fichier_image>"
    exit 1
fi

image_file="$1"
image_path="$WORKDIR/$image_file"

if [[ ! -f "$image_path" ]]; then
    "$LOG" add ERROR "│ Fichier image introuvable : $image_path"
    exit 1
fi

"$LOG" add DEBUG "│ Traitement de l'image : $image_file"

# Fonction de vérification et traitement des caractéristiques de l'image
process_image() {
    # Utiliser directement les variables globales (pas de local)
    # image_path et image_file sont les variables globales
    
    # Vérifier la taille et les dimensions de l'image
    local image_size=$(identify -format "%b" "$image_path")
    local image_width=$(identify -format "%w" "$image_path")
    local image_height=$(identify -format "%h" "$image_path")
    local image_depth=$(identify -format "%z" "$image_path")
    local image_colors=$(identify -format "%k" "$image_path")
    
    "$LOG" add DEBUG "│ Dimensions de l'image : ${image_width}x${image_height}, Taille : ${image_size}"
    "$LOG" add DEBUG "│ Profondeur de couleur : ${image_depth} bits, Couleurs : ${image_colors}"
    
    # Détecter si l'image est 1-bit (noir et blanc)
    local is_1bit=false
    if [[ "$image_depth" == "1" ]] || [[ "$image_colors" == "2" ]]; then
        is_1bit=true
        "$LOG" add DEBUG "│ Image 1-bit détectée - optimisation spéciale activée"
    fi
    
    # Vérification des dimensions de l'image
    if (( image_width < 1000 || image_height < 1500 )); then
        "$LOG" add WARNING "│ La qualité de l'image (${image_width}x${image_height}) peut être inadéquate."
    fi
    
    # Redimensionner l'image si elle excède les dimensions autorisées
    if (( image_width > 1300 || image_height > 2000 )); then
        "$LOG" add DEBUG "│ Redimensionnement de l'image au plus proche de 1024x1600 pixels."
        
        if [[ "$is_1bit" == true ]]; then
            # Redimensionnement spécial pour les images 1-bit
            "$LOG" add DEBUG "│ Redimensionnement 1-bit avec préservation du format."
            distr_magick_convert "$image_path" -resize 1024x1600\> -monochrome "$image_path"
        else
            # Redimensionnement normal
            distr_magick_convert "$image_path" -resize 1024x1600\> "$image_path"
        fi
    fi
    
    # Convertir en JPG si ce n'est pas déjà le cas
    if [[ ! "$image_file" =~ \.jpg$ ]]; then
        # Pour les images 1-bit, évaluer si la conversion JPG est pertinente
        if [[ "$is_1bit" == true ]]; then
            "$LOG" add DEBUG "│ Image 1-bit détectée - évaluation de la pertinence de conversion JPG."
            
            # Tester la conversion JPG pour comparaison
            local temp_jpg="${image_path%.*}_temp.jpg"
            local original_size=$(stat -c%s "$image_path")
            
            # Conversion JPG de test
            distr_magick_convert "$image_path" -quality 95 "$temp_jpg"
            local jpg_size=$(stat -c%s "$temp_jpg")
            
            if (( jpg_size < original_size )); then
                "$LOG" add DEBUG "│ Conversion JPG bénéfique pour image 1-bit (${jpg_size} vs ${original_size} octets)."
                rm "$image_path"
                mv "$temp_jpg" "${image_path%.*}.jpg"
                image_path="${image_path%.*}.jpg"
                image_file="$(basename "$image_path")"
            else
                "$LOG" add DEBUG "│ Format original plus léger pour image 1-bit (${original_size} vs ${jpg_size} octets)."
                rm "$temp_jpg"
            fi
        else
            # Traitement normal pour les images couleur
            "$LOG" add DEBUG "│ Conversion de l'image en format JPG."
            local new_image_path="${image_path%.*}.jpg"
            
            # Sauvegarder la taille du fichier original
            local original_size=$(stat -c%s "$image_path")
            
            # Effectuer la conversion
            distr_magick_convert "$image_path" "$new_image_path"
            
            # Comparer les tailles et garder le plus léger
            local converted_size=$(stat -c%s "$new_image_path")
            
            if (( converted_size < original_size )); then
                "$LOG" add DEBUG "│ Fichier converti plus léger (${converted_size} vs ${original_size} octets), conservation de la version JPG."
                rm "$image_path"  # Supprimer l'original
                image_path="$new_image_path"  # Modifier la variable globale
                image_file="$(basename "$new_image_path")"  # Modifier la variable globale
            else
                "$LOG" add DEBUG "│ Fichier original plus léger (${original_size} vs ${converted_size} octets), conservation de l'original."
                rm "$new_image_path"  # Supprimer la version convertie
            fi
        fi
    fi
    
    # Copier l'image finale dans le dossier EPUB
    mkdir -p "$IMG_DIR"
    local final_image_path="$IMG_DIR/$image_file"
    cp "$image_path" "$final_image_path"
    "$LOG" add DEBUG "│ Image finalisée copiée dans : $final_image_path"
}

# Extraire le basename pour gérer les noms de fichiers sans extension
image_basename=$(basename "$image_file" | cut -d. -f1)

# Vérifier si l'image est cover ou 4cover
if [[ "$image_basename" == "cover" || "$image_basename" == "4cover" ]]; then
    process_image  # Pas de paramètres, utilise les variables globales
    
    # Récupérer l'extension finale après traitement
    final_extension="${image_file##*.}"
    
    # Génération de la page XHTML correspondante
    if [[ "$image_basename" == "cover" ]]; then
        "$LOG" add DEBUG "│ Génération de la page de couverture au format xhtml."
        distr_python "$PY_DIR/generate_cover.py" "Images/$image_basename.$final_extension"
        "$LOG" add DEBUG "│ Génération xhtml terminée pour cover."
        # Mise à jour du manifest
        "$LOG" add DEBUG "│ Mise à jour du manifest pour cover."
        distr_python "$PY_DIR/update_manifest.py" "Images/$image_basename.$final_extension"
        distr_python "$PY_DIR/update_manifest.py" "Text/page_de_couverture.xhtml"
        distr_python "$PY_DIR/update_manifest.py" "Styles/style-cover.css"
        distr_python "$PY_DIR/update_index.py" "page_de_couverture.xhtml"
    elif [[ "$image_basename" == "4cover" ]]; then
        "$LOG" add DEBUG "│ Génération de la quatrième de couverture au format xhtml."
        distr_python "$PY_DIR/generate_cover.py" "Images/$image_basename.$final_extension"
        "$LOG" add DEBUG "│ Génération xhtml terminée pour 4cover."
        # Mise à jour du manifest
        "$LOG" add DEBUG "│ Mise à jour du manifest pour 4cover."
        distr_python "$PY_DIR/update_manifest.py" "Images/$image_basename.$final_extension"
        distr_python "$PY_DIR/update_manifest.py" "Text/quatrieme_couverture.xhtml"
        distr_python "$PY_DIR/update_manifest.py" "Styles/style-cover.css"
        distr_python "$PY_DIR/update_index.py" "quatrieme_couverture.xhtml"
    fi
else
    # Traitement générique pour les autres images
    process_image  # Pas de paramètres, utilise les variables globales
    
    # Récupérer l'extension finale après traitement
    final_extension="${image_file##*.}"
    
    "$LOG" add DEBUG "│ Mise à jour du manifest pour une image générique."
    distr_python "$PY_DIR/update_manifest.py" "Images/${image_basename}.$final_extension"
fi

"$LOG" add DEBUG "│ Traitement terminé pour l'image : $image_file"

exit 0
