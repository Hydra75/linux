#!/bin/bash 

#Verif ligne de commande 
if [ $# -ne 1 ]
    then
        echo "Nombre d'arguments incorrect"
	    echo "Usage : $0 arg[1] "
        exit 
fi
#Verifi si fichier est remplit/vide
if [ ! -s $1 ]
    then 
        echo "Fichier n'existe pas ou vide " 
        exit 
fi

#Verifier le contenu du fichier
while IFS=':' read -r prenom nom groupes sudo motdepasse; 
    do
        if [ $? -ne 0 ]
            then 
                echo "Format fichier non valide (Erreur en lecture)" 
        fi
        # Vérifier le format de chaque ligne prénom:nom:groupe1,groupe2,…:sudo:motdepasse 
        if [[ -z $prenom || -z $nom || -z $sudo || -z $motdepasse ]]; 
        then
            echo "Erreur : Format incorrect dans le fichier"
            exit 
        fi
    done < "$1"

#ajoute users au groupe sudoers si sudo : oui 
ajouteeSudo() {
    local login="$1"  # le nom d'utilisateur
    local sd="$2"  # le champ sudo  
    if [ "${sudo}" = "oui" ]; then
        sudo usermod -aG sudo "${login}"
    fi
}

#Création groupe et user
while IFS=':' read -r prenom nom groupes sudo motdepasse; do
    #Generer le login 
    login="${prenom:0:1}${nom}"
    login="${login,,}"
    if getent passwd $login > /dev/null; then
      i=1
      original_login=$login
      while grep -q "^$login:" /etc/passwd;
        do
            login="${original_login}$i"
            i=$(( $i + 1 )) 
        done
    fi

    #etc/passwd
    gecos="$prenom $nom"
    #Creer un utilisateur et un groupe primaire avec son nom si le champ groupes est vide 
    if [ -z "$groupes" ]
        then 
            sudo useradd -c "$gecos" -U -m -p "$(openssl passwd -1 "$motdepasse")" "$login"
            sudo chage -d 0 "$login" # changer le mdp lors de la 1er connexion
            ajouteeSudo $login $sd
    else
        IFS=',' read -ra ARRAY_GROUPES <<< "$groupes"
        for GROUPE in "${ARRAY_GROUPES[@]}"; 
            do  
                if ! getent group "$GROUPE" &>/dev/null; 
                    then addgroup "$GROUPE"
                fi
            done
        #Creer un utilisateur avec son groupe primaire
        sudo useradd -c "$gecos" -m -p "$(openssl passwd -1 "$motdepasse")" -g "${ARRAY_GROUPES[0]}" "$login" 
        sudo chage -d 0 "$login"
        ajouteeSudo $login $sd
        #Ajouter les groupes secondaires a l'utilisateur
        for GROUPE in "${ARRAY_GROUPES[@]}"; 
            do  
                if [ "${GROUPE}" != "${ARRAY_GROUPES[0]}" ]; 
                    then 
                        sudo usermod -aG "$GROUPE" "$login"
                fi
            done
    fi
    # Créer random des fichiers et des tailles
    nombre_de_fichiers=$((RANDOM % 6 + 5)) 
    for i in $(seq 1 $nombre_de_fichiers);  
        do
            taille_fichier=$((RANDOM % 46 + 5)) 
            dd if=/dev/urandom of="/home/$login/$nom_fichier" bs=512K count=$taille_fichier status=none
            
        done
done < "$1"

