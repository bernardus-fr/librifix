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

# Chemin vers le répertoire temporaire et fichier JSON
TEMP_DIR="./temp"
METADATA_FILE="$TEMP_DIR/metadata.json"

# Dépendances
LOG_SCRIPT="./scripts/bash/log_manager.sh" 

# Fonction pour vérifier et créer le répertoire temp si nécessaire
if [ ! -d "$TEMP_DIR" ]; then
  mkdir -p "$TEMP_DIR"
  # Entrée log
  "$LOG_SCRIPT" add INFO "│ Répertoire temporaire créé : $TEMP_DIR"
fi

# Fenêtre pour les données obligatoires
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
    "$LOG_SCRIPT" add INFO "└-Annulation par l'utilisateur lors de la saisie des données obligatoires."
    exit 1
  fi

  IFS="|" read -r title creator language <<< "$output"

  if [[ -z "$title" || -z "$creator" || -z "$language" ]]; then
    zenity --error --text="Veuillez remplir tous les champs s'il vous plaît."
    # Entrée log
    "$LOG_SCRIPT" add INFO "│ Champs manquants lors de la saisie des données obligatoires."
  else
    # Entrée log
    "$LOG_SCRIPT" add INFO "│ Données obligatoires collectées avec succès."
    break
  fi
done

# Enregistrement des données obligatoires dans metadata.json
cat > "$METADATA_FILE" <<EOF
{
  "title": "$title",
  "creator": "$creator",
  "language": "$language"
}
EOF
# Entrée log
"$LOG_SCRIPT" add INFO "│ Données obligatoires enregistrées dans $METADATA_FILE."

# Fenêtre pour les données facultatives
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
  "$LOG_SCRIPT" add INFO "│ Annulation par l'utilisateur lors de la saisie des données facultatives."
  rm "$METADATA_FILE"
  exit 1
fi

IFS="|" read -r identifier date publisher contributor subject source rights description <<< "$output"

# Ajout des données facultatives si elles existent
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
  "$LOG_SCRIPT" add INFO "│ Données facultatives ajoutées au fichier $METADATA_FILE."
fi

# Fenêtre pour sélectionner le dossier de travail
while true; do
  workdir=$(zenity --file-selection --directory --title="Sélectionnez le dossier de travail")

  if [ $? -ne 0 ]; then
    # Entrée log
    "$LOG_SCRIPT" add INFO "│ Annulation par l'utilisateur lors de la sélection du dossier de travail."
    exit 1
  fi

  if [ -d "$workdir" ]; then
    jq --arg workdir "$workdir" '. + {workdir: $workdir}' "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
    # Entrée log
    "$LOG_SCRIPT" add INFO "│ Dossier de travail ajouté au fichier $METADATA_FILE : $workdir."
    break
  else
    zenity --error --text="Le chemin sélectionné n'est pas valide. Veuillez réessayer."
    # Entrée log
    "$LOG_SCRIPT" add INFO "│ Chemin invalide lors de la sélection du dossier de travail."
  fi
done

# Fin du script
"$LOG_SCRIPT" add INFO "│ Métadonnées collectées et enregistrées avec succès."
exit 0
