#!/bin/bash

#set -x
typeset -A PARAM_CLIENT_CONF_AA
PARAM_CONF_LIST=$(ls template.conf.d/*)

PARAM_SIZE_CHECKER_SLEEP_TIME=10;


BIN_ECHO=/bin/echo;

function FUNC_SIZE_CHECKER
{
        local TGT_F_BF=$(stat -c %s $PARAM_TARGET_FILE)
        sleep $PARAM_SIZE_CHECKER_SLEEP_TIME
        local TGT_F_AF=$(stat -c %s $PARAM_TARGET_FILE)

        if [ "$TGT_F_BF" -eq "$TGT_F_AF" ]; then
                $BIN_ECHO -e "True"
                return 0; #Return True
        else
                $BIN_ECHO -e "False"
                return 1; #Return False
        fi
}


#########################################################################
#                                                                       #
# 2.) Read conf and save content in global conf associate array.        #
#                                                                       #
########################################################################
function FUNC_READ_CONF {
        local PARAM_FUNC_READ_FILE=$1
        #echo "[i]:"$_func_param_f
        while read line
        do
          if  echo $line|grep -F : &>/dev/null
          then
                # Remove leading trailing whitespace.
                shopt -s extglob
                temp_attribute_name=$(echo $line |cut -d ':' -f 1)
                temp_attribute_name=${temp_attribute_name##+([[:space:]])}
                client_attribute_name=${temp_attribute_name%%+([[:space:]])}
                temp_attribute=$(echo $line |cut -d ':' -f 2-)
                temp_attribute=${temp_attribute##+([[:space:]])}
                client_attribute=${temp_attribute%%+([[:space:]])}
                #temp_attribute="${line//[[:space:]]/}"
                if [[ $temp_attribute == "" ]]
                then
                    echo -e "Parameter $temp_attribute_name is empty. Abort."
                    exit 1
                else
                    PARAM_CLIENT_CONF_AA[$client_attribute_name]=$client_attribute
                fi
          fi
        done < $PARAM_FUNC_READ_FILE

        return
}

function FUNC_LOOP_SOURCE_DIR {

#echo -e "${PARAM_CLIENT_CONF_AA[@]}."
#echo -e "${!PARAM_CLIENT_CONF_AA[@]}."
    echo -e "[i]: ${PARAM_CLIENT_CONF_AA[source_dir]}."
    #if source_dir exists, list the directory
    temp_source_dir=${PARAM_CLIENT_CONF_AA[source_dir]}
    if [[ -d $temp_source_dir ]]
    then
        ls -laR $temp_source_dir
    fi
}

#for f in $PARAM_CONF_LIST; do
#        FUNC_READ_CONF $f
#done #done for
#
#########################################################################
#                                                                       #
# 2.) Loop through each config file via function FUNC_READ_CONF, and    #
#                                                                       #
########################################################################
for f in $PARAM_CONF_LIST; do
    echo -e "\n[i]: Read Client config files\t: $f"
    echo "[i]: ---------------------------------------------------------"
    FUNC_READ_CONF $f
    FUNC_LOOP_SOURCE_DIR $f
    #for key in  "${!PARAM_CLIENT_CONF_AA[@]}" ; do
    #    echo -e "[i]: $key\t: ${PARAM_CLIENT_CONF_AA[$key]}"
    #done |sort -r
done
exit
