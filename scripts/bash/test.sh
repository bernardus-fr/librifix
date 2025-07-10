#!/bin/bash

source scripts/bash/utils.sh

language="Italien"

iso_code=$(get_lang_iso_code "$language")

echo "le code iso reçu est $iso_code"