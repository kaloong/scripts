#!/bin/bash

#set -x
typeset -A config
conf_list=$(ls template.conf.d/*)



#########################################################################
#                                                                       #
# 2.) Read conf and save content in global conf associate array.        #
#                                                                       #
########################################################################
function read_conf {
        local _func_param_f=$1
        #echo "[i]:"$_func_param_f
        while read line
        do
          if  echo $line|grep -F : &>/dev/null
          then
                temp_attribute_name=$(echo $line |cut -d ':' -f 1)
                temp_attribute=$(echo $line |cut -d ':' -f 2-)
                if [[ $(echo $line|cut -d ':' -f 2-) == "" ]]
                then
                    echo -e "Parameter $temp_attribute_name is empty. Abort."
                    exit 1
                else
                    #client_attribute_name=${temp_attribute_name//[[:blank:]]/}
                    client_attribute_name=${temp_attribute_name//[[:space:]]/}
                    client_attribute=${temp_attribute//[[:space:]]/}
                    config[$client_attribute_name]=$client_attribute
                fi
                #echo "[i]:"${config[$client_attribute]}
          fi
        done < $_func_param_f
        return
}

# Perform trict parameter checks with regex rules.
# This will ensure that parameters are clean.
function check_params {
    for key in  "${!config[@]}" ; do
        if [[   "${key^^}" == "SOURCE_USER" ]]
        then
            if [[ -n ${config[$key]} ]]
            then
                echo -e "[i] $key\t\t exists"
            else
                echo -e "[i] $key\t\t does not exists"
            fi
            #Check if user exist
            if [[ $(id ${config[$key]} > /dev/null 2>&1 ; echo $?) == 0 ]]
            then
                echo -e "[i] local source user exists"
            else
                echo -e "[i] local source user does not exists"
            fi
            continue
        fi
        if [[   "${key^^}" == "SOURCE_KEY" ]]
        then
            if [[ -f ${config[$key]} ]]
            then
                echo -e "[i] $key\t\t exists"
            else
                echo -e "[i] $key\t\t does not exists"
            fi
            continue
        fi
        if [[   "${key^^}" == "SOURCE_HOST" ]]
        then
            if [[ -n ${config[$key]} ]]
            then
                echo -e "[i] $key\t\t exists"
            else
                echo -e "[i] $key\t\t does not exists"
            fi
            continue
        fi
        if [[   "${key^^}" == "SOURCE_DIR" ]]
        then
            if [[ -n ${config[$key]} ]]
            then
                echo -e "[i] $key\t\t exists"
            else
                echo -e "[i] $key\t\t does not exists"
            fi
            continue
        fi
        if [[   "${key^^}" == "DESTINATION_USER" ]]
        then
            if [[ -n ${config[$key]} ]]
            then
                echo -e "[i] $key\t\t exists"
            else
                echo -e "[i] $key\t\t does not exists"
            fi
            continue
        fi
        if [[   "${key^^}" == "DESTINATION_KEY" ]]
        then
            if [[ -n ${config[$key]} ]]
            then
                echo -e "[i] $key\t\t exists"
            else
                echo -e "[i] $key\t\t does not exists"
            fi
            continue
        fi
        if [[   "${key^^}" == "DESTINATION_HOST" ]]
        then
            if [[ -n ${config[$key]} ]]
            then
                echo -e "[i] $key\t\t exists"
            else
                echo -e "[i] $key\t\t does not exists"
            fi
            continue
        fi
        if [[   "${key^^}" == "DESTINATION_DIR" ]]
        then
            if [[ -n ${config[$key]} ]]
            then
                echo -e "[i] $key\t\t exists"
            else
                echo -e "[i] $key\t\t does not exists"
            fi
            continue
        fi
        if [[   "${key^^}" == "LOG_FILENAME" ]]
        then
            if [[ -n ${config[$key]} ]]
            then
                echo -e "[i] $key\t\t exists"
            else
                echo -e "[i] $key\t\t does not exists"
            fi
            continue
        fi
        if [[   "${key^^}" == "LOG_FORMAT" ]]
        then
            echo -e "[d]: ${config[$key]}"
            if [[ -n ${config[$key]} ]]
            then
                echo -e "[i] $key\t\t exists"
            else
                echo -e "[i] $key\t\t does not exists"
            fi
            continue
        fi
    done |sort -r
    return
}
#for f in $conf_list; do
#        read_conf $f
#done #done for
#
#########################################################################
#                                                                       #
# 2.) Loop through each config file via function read_conf, and         #
#                                                                       #
########################################################################
for f in $conf_list; do
    echo -e "\n[i]: Read config file\t: $f"
    echo "[i]: ---------------------------------------------------------"
    read_conf $f
    check_params
    #for key in  "${!config[@]}" ; do
    #    echo -e "[i]: $key\t: ${config[$key]}"
    #done |sort -r
done
exit
