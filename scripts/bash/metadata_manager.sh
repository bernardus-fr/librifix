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
#  Gestion des métadonnées du livre. Utilise des fenêtre Zenity pour interragir avec
# l'utilisateur: métadonnées obligatoires - optionnelles- chemin du dossier de travail.
#  Les métadonnées sont conservées dans le fichiers metadata.json


# Fonction pour vérifier et créer le répertoire temp si nécessaire
if [ ! -d "$TEMP_DIR" ]; then
  mkdir -p "$TEMP_DIR"
  # Entrée log
  "$LOG" add DEBUG "│ Répertoire temporaire créé : $TEMP_DIR"
fi

#   1) RÉCUPÉRATION DES DONNÉES OBLIGATOIRES titre - auteur - langue
# a - Fenêtre pour les données obligatoires
while true; do
  output=$(zenity --forms \
    --title="Métadonnées obligatoires" \
    --text="Tous les champs sont obligatoires." \
    --add-entry="Titre" \
    --add-entry="Auteur" \
    --add-entry="Langue" \
    --ok-label="Suivant" \
    --cancel-label="Annuler")

  if [ $? -ne 0 ]; then
    # Entrée log
    "$LOG" add DEBUG "└-Annulation par l'utilisateur lors de la saisie des données obligatoires."
    "$EXIT_SCRIPT" "annulation"
    exit 0
  fi

  IFS="|" read -r title creator language <<< "$output"

  if [[ -z "$title" || -z "$creator" || -z "$language" ]]; then
    zenity --error --text="Veuillez remplir tous les champs s'il vous plaît."
    # Entrée log
    "$LOG" add DEBUG "│ Champs manquants lors de la saisie des données obligatoires."
  else
    # Entrée log
    "$LOG" add DEBUG "│ Données obligatoires collectées avec succès."
    break
  fi

  # Ajouter vérification que la langue soit bien prise en charge

done

#    -----------------

# b - Enregistrement des données obligatoires dans metadata.json
cat > "$METADATA_FILE" <<EOF
{
  "title": "$title",
  "creator": "$creator",
  "language": "$language"
}
EOF
# Entrée log
"$LOG" add DEBUG "│ Données obligatoires enregistrées dans $METADATA_FILE."

# --------------------------------------------------------------



#   2) RÉCUPÉRATION DES DONNÉES FACULTATIVES
# a - Fenêtre pour les données facultatives
output=$(zenity --forms \
  --title="Métadonnées facultatives" \
  --text="Données facultatives (remplissez uniquement ce que vous souhaitez)." \
  --add-entry="Identifiant (ISBN)" \
  --add-entry="Date (YYYY-MM-DD)" \
  --add-entry="Éditeur" \
  --add-entry="Contributeurs" \
  --add-entry="Catégorie" \
  --add-entry="Source (titre original)" \
  --add-entry="Droits" \
  --add-entry="Description" \
  --ok-label="Suivant" \
  --cancel-label="Annuler")

if [ $? -ne 0 ]; then
  # Entrée log
  "$LOG" add DEBUG "│ Annulation par l'utilisateur lors de la saisie des données facultatives."
  "$EXIT_SCRIPT" "annulation"
  exit 0
fi

IFS="|" read -r identifier date publisher contributor subject source rights description <<< "$output"

#    -----------------

# b - Ajout des données facultatives si elles existent
if [[ -n "$identifier" || -n "$date" || -n "$publisher" || -n "$contributor" || -n "$subject" || -n "$source" || -n "$rights" || -n "$description" ]]; then
  jq \
    --arg identifier "$identifier" \
    --arg date "$date" \
    --arg publisher "$publisher" \
    --arg contributor "$contributor" \
    --arg subject "$subject" \
    --arg source "$source" \
    --arg rights "$rights" \
    --arg description "$description" \
    '. + {identifier: $identifier, date: $date, publisher: $publisher, contributor: $contributor, subject: $subject, source: $source, rights: $rights, description: $description}' \
    "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
  # Entrée log
  "$LOG" add DEBUG "│ Données facultatives ajoutées au fichier $METADATA_FILE."
fi

# --------------------------------------------------------------



#   2) RÉCUPÉRATION DU DOSSIER DE TRAVAIL
# a - Fenêtre pour sélectionner le dossier de travail
while true; do
  workdir=$(zenity --file-selection --directory --title="Sélectionnez le dossier de travail" --filename="~/")

  if [ $? -ne 0 ]; then
    # Entrée log
    "$LOG" add DEBUG "│ Annulation par l'utilisateur lors de la sélection du dossier de travail."
    "$EXIT_SCRIPT" "annulation"
    exit 0
  fi

  if [ -d "$workdir" ]; then

#    -----------------

# b - Ajout des données au metadata
    jq --arg workdir "$workdir" '. + {workdir: $workdir}' "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
    # Entrée log
    "$LOG" add DEBUG "│ Dossier de travail ajouté au fichier $METADATA_FILE : $workdir."
    break
  else
    zenity --error --text="Le chemin sélectionné n'est pas valide. Veuillez réessayer."
    # Entrée log
    "$LOG" add DEBUG "│ Chemin invalide lors de la sélection du dossier de travail."
  fi
done

# Fin du script
"$LOG" add DEBUG "│ Métadonnées collectées et enregistrées avec succès."
