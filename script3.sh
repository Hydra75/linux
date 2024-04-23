#!/bin/bash

# Définir l'emplacement du fichier qui contiendra la liste des fichiers avec SUID/SGID
current_list="/tmp/current_suid_sgid_list.txt"
previous_list="/tmp/previous_suid_sgid_list.txt"


find / -perm /6000 2>/dev/null > "$current_list"


if [ -f "$previous_list" ]; then
    # Compare
    differences=$(diff "$previous_list" "$current_list")
    
    # Vérifier si des différences ont été trouvées
    if [ ! -z "$differences" ]; then
        echo "Avertissement: Des différences ont été détectées entre les fichiers SUID/SGID actuels et précédents."
        echo "Différences:"
        echo "$differences"
        
        # Pour chaque fichier différent, afficher sa date de dernière modification
        echo "Dates de modification des fichiers modifiés :"
        for file in $(echo "$differences" | grep '>' | cut -d' ' -f2-); do
            # Afficher la date de dernière modification du fichier
            echo "$file - $(stat -c %y "$file")"
        done
    else
        echo "Aucune différence détectée."
    fi
else
    echo "C'est la première exécution du script. Aucune comparaison n'est possible."
fi

# Déplacer le current_list vers previous_list pour la prochaine exécution
mv "$current_list" "$previous_list"
