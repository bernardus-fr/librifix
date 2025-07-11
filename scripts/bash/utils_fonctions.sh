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
#  Définir fonctions récurentes, etc et centraliser
# les récurences dans le code pour alléger chaque script.


# Affichage d'une fenêtre d'ereur Zenity
afficher_message() {
    local status="$1"
    local message="$2"

    case "$status" in
        info )
            zenity --info --title="$LANG_TITLE_INFO" --text="$message"
            ;;
        warning )
            zenity --warning --title="$LANG_TITLE_WARNING" --text="$message"
            ;;
        error )
            zenity --error --title="$LANG_TITLE_ERROR" --text="$message"
            ;;
    esac
}

# Fonction d'initialisation du config.ini
initialize_config() {
    "$LOG" add DEBUG "Début de la configuration du programme"
    # Détecter la langue du système
    SYS_LANG=$(locale | grep "^LANG=" | cut -d= -f2 | cut -d_ -f1)

    # Si aucune langue détectée, utiliser "en" par défaut
    [[ -z "$SYS_LANG" ]] && SYS_LANG="en"
    "$LOG" add DEBUG "Langue du système détectée $SYS_LANG"

    # -------------

    # Détecter la distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        "$LOG" add DEBUG "Distribution système détectée $DISTRO"
    elif command -v lsb_release &>/dev/null; then
        DISTRO=$(lsb_release -i | awk -F: '{print $2}' | xargs)
        "$LOG" add DEBUG "Distribution système détectée $DISTRO"
    else
        "$LOG" add WARNING "Impossible de détecter la distribution."
    fi

    # -------------

    # Créer le fichier config.ini avec la section [General]
    cat <<EOL > "$CONFIG_FILE"
[General]
language=$SYS_LANG
distrib=$DISTRO
last_exit=run
EOL

    "$LOG" add DEBUG "Fichier de configuration initialisé : $CONFIG_FILE"
}

# Fonction de vérification et installation des dépendances system du programme
check_and_install_system_dependencies() {
    # Liste des dépendances système
    
    DISTRO=$(grep "^distrib=" "$CONFIG_FILE" | cut -d '=' -f2)
    
    # Vérifications et installation en fonction de la distribution linux.
    case $DISTRO in
        ubuntu|debian|linuxmint) # Distribution Basée sur apt et dpgk
            "$LOG" add DEBUG "Vérification des dépendances système pour $DISTRO..."
            local dependencies=("zenity" "zip" "imagemagick" "jq" "default-jre" "python3" "python3-pip" "python3-bs4")
            for pkg in "${dependencies[@]}"; do
                if ! dpkg -s "$pkg" &>/dev/null; then
                    "$LOG" add DEBUG "$pkg non trouvé. Installation en cours..."
                    sudo apt-get install -y "$pkg"
                else
                    "$LOG" add DEBUG "$pkg : [OK]"
                fi
            done
            ;;
        fedora|centos|rhel) # Distribution basée sur dnf ou yum
            "$LOG" add DEBUG "Vérification des dépendances système pour $DISTRO..."
            local dependencies=("zenity" "zip" "ImageMagick" "jq" "java-latest-openjdk" "python3" "python3-pip")
            for pkg in "${dependencies[@]}"; do
                if command -v dnf &>/dev/null; then # Distribution basée sur dnf
                    if ! dnf list installed "$pkg" &>/dev/null; then
                        "$LOG" add DEBUG "$pkg non trouvé. Installation en cours..."
                        sudo dnf install -y "$pkg"
                    else
                        "$LOG" add DEBUG "$pkg : [OK]"
                    fi
                elif command -v yum &>/dev/null; then # Distribution basée sur yum
                    if ! yum list installed "$pkg" &>/dev/null; then
                        "$LOG" add DEBUG "$pkg non trouvé. Installation en cours..."
                        sudo yum install -y "$pkg"
                    else
                        "$LOG" add DEBUG "$pkg : [OK]"
                    fi
                else
                    echo "Aucun gestionnaire de paquets trouvé (ni dnf ni yum)."
                fi
            done
            ;;
        opensuse) # Pour openSUSE avec zypper
            "$LOG" add DEBUG "Vérification des dépendances système pour $DISTRO..."
            local dependencies=("zenity" "zip" "ImageMagick" "jq" "java-21-openjdk" "python312" "python312-pip" "python312-bs4")
            for pkg in "${dependencies[@]}"; do
                if ! zypper se --installed-only "$pkg" &>/dev/null; then
                    "$LOG" add DEBUG "$pkg non trouvé. Installation en cours..."
                    sudo zypper install -y "$pkg"
                else
                    "$LOG" add DEBUG "$pkg : [OK]"
                fi
            done
            ;;
        arch|cachyos) # Pour Arch Linux avec pacman
            "$LOG" add DEBUG "Vérification des dépendances système pour $DISTRO..."
            local dependencies=("zenity" "zip" "imagemagick" "jq" "jre-openjdk" "python" "python-pip" "python-virtualenv" "python-pipenv" "python-beautifulsoup4" "calibre")
            for pkg in "${dependencies[@]}"; do
                if ! pacman -Q "$pkg" &>/dev/null; then
                    "$LOG" add DEBUG "$pkg non trouvé. Installation en cours..."
                    sudo pacman -S --noconfirm "$pkg"
                else
                    "$LOG" add DEBUG "$pkg : [OK]"
                fi
            done
            ;;
        *)
            "$LOG" add WARNING "Gestionnaire de paquets inconnu pour la distribution $DISTRO..."
            afficher_message error "$LANG_TEXT_ERROR_DEPEND_DISTRO"
            ;;
    esac

    
    "$LOG" add DEBUG "Vérification des dépendances système terminée."
}

# Fonction de vérification et installation des dépendances python du programme
check_and_install_python_dependencies() {
    # Liste des modules Python
    local modules=("bs4" "os" "json" "pathlib" "subprocess" "re" "sys" "xml.etree.ElementTree" "datetime" "time" "uuid")

    "$LOG" add DEBUG "Vérification des dépendances python..."

    case "$DISTRO" in
        ubuntu|debian|linuxmint|fedora|centos|rhel)
            for module in "${modules[@]}"; do
                if ! python3 -c "import $module" &>/dev/null; then
                    "$LOG" add DEBUG "Le module $module est manquant. Installation en cours..."
                    pip3 install "$module"
                else
                    "$LOG" add DEBUG "$module [OK]]"
                fi
            done
            ;;
        opensuse*)
            for module in "${modules[@]}"; do
                if ! python3.12 -c "import $module" &>/dev/null; then
                    "$LOG" add DEBUG "Le module $module est manquant. Installation en cours..."
                    pip3.12 install "$module"
                else
                    "$LOG" add DEBUG "$module [OK]]"
                fi
            done
            ;;
        arch)
            for module in "${modules[@]}"; do
                if ! python -c "import $module" &>/dev/null; then
                    "$LOG" add DEBUG "Le module $module est manquant. Installation en cours..."
                    pip install "$module"
                else
                    "$LOG" add DEBUG "$module [OK]]"
                fi
            done
            ;;
    esac


    "$LOG" add DEBUG "Vérification des dépendances python terminée."
}

# Fonction de vérification de l'intégrité du programme
check_program_integrity() {
    "$LOG" add DEBUG "Vérification de l'intégrité du programme..."

    # Liste des scripts Bash
    local scripts_bash=(
        "$LOG"
        "$EXIT_SCRIPT"
        "$CHECK_TEMP"
        "$META_MANAG"
        "$TRAIT_WORKDIR"
        "$INSERT_FILES"
        "$TRAIT_XHTML"
        "$TRAIT_IMG"
        "$TRAIT_OTH"
        "$EPUBIZER"
    )

    # Liste des scripts Python
    local scripts_python=(
        "$GEN_UUID"
        "$ANALYSE_FILES"
        "$SYNC_CHAP_NOTES"
        "$TRAIT_CHAP_REF"
        "$TRAIT_NOTES_REF"
        "$TRAIT_CHAP_HTML"
        "$TRAIT_NOTES_HTML"
        "$GEN_COVER"
        "$UPDATE_META_CONTENT"
        "$UPDATE_META_GARDE"
        "$UPDATE_META_TOC"
        "$UPDATE_META_NAV"
        "$MAN_JSON"
        "$UPDATE_MANIFEST"
        "$UPDATE_INDEX"
    )

    # Liste des autres fichiers
    local others_files=(
        "./utils/templates/epub/mimetype"
        "./utils/templates/epub/META-INF/container.xml"
        "./utils/templates/epub/OEBPS/content.opf"
        "./utils/templates/epub/OEBPS/toc.ncx"
        "./utils/templates/epub/OEBPS/Styles/style-garde.css"
        "./utils/templates/epub/OEBPS/Styles/style-global.css"
        "./utils/templates/epub/OEBPS/Styles/style-index.css"
        "./utils/templates/epub/OEBPS/Styles/style-notes.css"
        "./utils/templates/epub/OEBPS/Text/nav.xhtml"
        "./utils/templates/epub/OEBPS/Text/page_de_garde.xhtml"
        "./lang/files_name.json"
        "./lang/iso_code_lang.json"
        "./lang/interface/fr.json"
        "./lang/interface/it.json"
        "./lang/interface/en.json"
        "./lang/interface/es.json"
        "./lang/interface/de.json"
        "./lang/interface/da.json"
        "./lang/interface/hu.json"
        "./lang/interface/nl.json"
        "./lang/interface/pl.json"
        "./lang/interface/pt.json"
        "./lang/epub/fr.txt"
    )

    # Vérification des scripts Bash
    for script in "${scripts_bash[@]}"; do
        if [[ ! -f "$script" ]]; then
            "$LOG" add CRITICAL "$script : [MANQUANT]"
            afficher_message "error" "$LANG_MESSAGE_FILE_NOT_FOUND : $script - $LANG_MESSAGE_RE_INSTALL"
            "$EXIT_SCRIPT" "error"
            exit 1
        elif [[ ! -x "$script" ]]; then
            "$LOG" add WARNING "$script n'est pas exécutable. Correction..."
            chmod +x "$script"
            "$LOG" add DEBUG "$script : [OK]"
        else
            "$LOG" add DEBUG "$script : [OK]"
        fi
    done

    # Vérification des scripts Python
    for script in "${scripts_python[@]}"; do
        if [[ ! -f "$script" ]]; then
            "$LOG" add CRITICAL "$script : [MANQUANT]"
            afficher_message error "$LANG_MESSAGE_FILE_NOT_FOUND : $script - $LANG_MESSAGE_RE_INSTALL"
            "$EXIT_SCRIPT" "error"
            exit 1
        else
            "$LOG" add DEBUG "$script : [OK]"
        fi
    done

    # Vérification des utils
    for file in "${others_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            "$LOG" add CRITICAL "$file : [MANQUANT]"
            afficher_message error "$LANG_MESSAGE_FILE_NOT_FOUND : $script - $LANG_MESSAGE_RE_INSTALL"
            "$EXIT_SCRIPT" "error"
            exit 1
        else
            "$LOG" add DEBUG "$file : [OK]"
        fi
    done

    "$LOG" add DEBUG "Vérification de l'intégrité terminée avec succès."
}

check_last_exit_status() {
    # Vérifie si le fichier de configuration existe
    if [[ ! -f "$CONFIG_FILE" ]]; then
        "$LOG" add ERROR "Fichier de configuration introuvable : $CONFIG_FILE"
        exit 1
    fi

    # Récupère la valeur de last_exit dans le fichier config.ini
    local last_exit_status
    last_exit_status=$(grep "^last_exit=" "$CONFIG_FILE" | cut -d '=' -f2)

    # Définition du program comme en cours
    # Vérifie si la section [General] existe, sinon l'ajoute
    if ! grep -q "^\[General\]" "$CONFIG_FILE"; then
        echo -e "\n[General]" >> "$CONFIG_FILE"
    fi

    # Met à jour ou ajoute la valeur last_exit avec "run"
    if grep -q "^last_exit=" "$CONFIG_FILE"; then
        sed -i "s|^last_exit=.*|last_exit=run|" "$CONFIG_FILE"
    else
        echo "last_exit=run" >> "$CONFIG_FILE"
    fi

    "$LOG" add DEBUG "État du programme enregistré : run"

    # Si la valeur est vide, on considère que c'est un premier lancement
    if [[ -z "$last_exit_status" ]]; then
        "$LOG" add DEBUG "Aucun statut trouvé, probablement un premier lancement."
        return 0
    fi

    "$LOG" add DEBUG "Le dernier état du programme était : $last_exit_status"

    # Affiche le dernier statut et retourne un code différent selon le cas
    case "$last_exit_status" in
        "success")
            return 0
            ;;
        "cancel")
            return 0
            ;;
        "run")
            return 1
            ;;
        "error")
            return 1
            ;;
        *)
            "$LOG" add ERROR "Valeur inconnue pour last_exit : $last_exit_status"
            return 1
            ;;
    esac
}

get_lang_iso_code() {
    local lang="$1"

    # Conversion de la casse en minuscule
    local language=$(echo "$language" | tr '[:upper:]' '[:lower:]')

    # Recherche du code ISO avec jq
    iso_code=$(jq -r --arg lang "$language" '
        to_entries[] | select(.value[] | ascii_downcase == $lang) | .key' "$ISO_LANG"
    )

    # Vérification du résultat
    if [[ -n "$iso_code" ]]; then
        echo "$iso_code"
    else
        echo "en"
    fi

}
