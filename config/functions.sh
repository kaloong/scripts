#!/bin/bash

function FUNC_VALIDATE_CFG_V1 {
    #local aa_name=$1
    local cfg=$2
    echo -e "---> $cfg"
    IFS="="
    while read -r name value
    do
        #Trim whitespace front and back
        trimmed_name_front="${name%%*( )}"
        trimmed_name_back="${trimmed_name_front##*( )}"
        trimmed_value_front="${value%%*( )}"
        trimmed_value_back="${trimmed_value_front##*( )}"
        name=$trimmed_name_back
        value=$trimmed_value_back
        #echo -e "After --> [$name] [$value]"
        if [[ ! ${name:0:1} =~ "#" ]]; then
            #declare "${aa_name}"["$name"]="$i"
            declare -A aa[$name]="$value"
        fi
    done < $cfg
    echo -e "---------------------"
    if  [[  "${aa[CLIENT_USER]^^}" == "" ]]; then
    #if  [[  -z "${aa[CLIENT_USER]}" || "${aa[CLIENT_USER]^^}" == "" ]]; then
        echo -e "[-] Found a fake user error on CLIENT_USER"
        exit 1
    fi
    if  [[ -z "${aa[CLIENT_PASS]}" || "${aa[CLIENT_PASS]}" == "" ]]; then
        echo -e "[-] Found a fake pass error on CLIENT_PASS"
        exit 1
    fi
    return 0
}

function FUNC_VALIDATE_CFG_V0 {
    shopt -s nullglob
    #declare -A "${aa_name}"[name]="$i"
    local aa_name_1=$1
    local cfg=$2
    declare -A "${aa_name_1}"
    echo -e "---> $cfg"
    #source $cfg
    echo -e "xxx ${aa_name_1[CLIENT_USER]}"
    #source "${cfg[name]}"
    #${aa['CLIENT_USER']}="${CLIENT_USER}"
    declare -A "${aa_name_1}["name"]"
    declare aa_tmp="${aa_name_1}"
    x=234
    IFS="="
    while read -r name value
    do
        #echo -e "$name $value"
        if [[ ! ${name:0:1} == "#" ]]; then
            #declare "${aa_name}"["$name"]="$i"
            #declare -A "${aa_name_1}"[$name]="$value"
            set -x
            aa_tmp[$name]="$value"
            set +x
            #declare aa_key="${aa_tmp}[@]"
            #declare aa_val="${!aa_tmp}[@]"
            echo -e "->$name ${!aa_tmp[*]} ${aa_tmp[@]}"
    echo -e "-> ${aa_tmp[CLIENT_DB]}"
        fi
    done < $cfg
    echo -e "-> ${aa_tmp[234]}"
    echo -e "---------------------"
#    if  [[ "${CLIENT_USER^^}" == "CLIENT " || "${CLIENT_USER}" == "" ]]; then
#        echo -e "[-] Found a fake user error on CLIENT_USER"
#        exit 1
#    fi
#    if  [[ "${CLIENT_PASS^^}" == "PASSWORD5678" || "${CLIENT_PASS}" == "" ]]; then
#        echo -e "[-] Found a fake pass error on CLIENT_PASS"
#        exit 1
#    fi
    return 0
}
