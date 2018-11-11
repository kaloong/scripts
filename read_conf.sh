#!/bin/bash

#set -x
typeset -A PARAM_CLIENT_CONF_AA
PARAM_CONF_LIST=$(ls template.conf.d/*)

PARAM_SIZE_CHECKER_SLEEP_TIME=2;


BIN_ECHO=/bin/echo;

function FUNC_SIZE_CHECKER
{

    #echo -e "[+]: $1"
    local TGT_F_BF=$(stat -c %s $1)
    sleep $PARAM_SIZE_CHECKER_SLEEP_TIME
    local TGT_F_AF=$(stat -c %s $1)

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

function FUNC_TRANSFER_FILE {
    local param_target_dir=$1
    local param_target_base_dir=$(basename $1)
    local param_target_file=$2
    #echo -e "[T]: └── Transfer $param_target_file from ${PARAM_CLIENT_CONF_AA[source_dir]} to ${PARAM_CLIENT_CONF_AA[destination_dir]}"
    echo -e "[T]: └── Transfer $param_target_file from $param_target_dir to ${PARAM_CLIENT_CONF_AA[destination_dir]}/$param_target_base_dir"
    return 0
}
function FUNC_INSPECT_SOURCE_DIR {

#echo -e "${PARAM_CLIENT_CONF_AA[@]}."
#echo -e "${!PARAM_CLIENT_CONF_AA[@]}."
#echo -e "[i]: ${PARAM_CLIENT_CONF_AA[source_dir]}."
    #if source_dir exists, list the directory
    client_source_dir=${PARAM_CLIENT_CONF_AA[source_dir]}
    if [[ -d $client_source_dir ]]
    then
        temp_file=$(find $client_source_dir -maxdepth 1)
        for f in $temp_file; do
            if [[ ! -d $f ]]
            then
                dname=$(dirname $f)
                fname=$(basename $f)
                check_result=$(FUNC_SIZE_CHECKER $f)
                if [[ ${check_result^^} == "TRUE" ]]
                then
                    echo -e "[i]: $f status is good."
                    #or echo -e "[i]: $f $(echo $?)"
                    FUNC_TRANSFER_FILE $dname $fname
                else
                    echo -e "[i]: $f status is still changing. Try back again."
                    #Add to later
                fi
            fi
        done
        temp_dir=$(find $client_source_dir -type d)
        for f in $temp_dir; do
            if [[ -d $f ]]
            then
                dname=$(dirname $f)
                fname=$(basename $f)
                check_result=$(FUNC_SIZE_CHECKER $f)
                if [[ ${check_result^^} == "TRUE" ]]
                then
                    echo -e "[i]: $f status is good."
                    #or echo -e "[i]: $f $(echo $?)"
                    FUNC_TRANSFER_FILE $dname $fname
                else
                    echo -e "[i]: $f status is still changing. Try back again."
                    #Add to later
                fi
            fi
        done
    fi
    return 0
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
    FUNC_INSPECT_SOURCE_DIR $f
    #for key in  "${!PARAM_CLIENT_CONF_AA[@]}" ; do
    #    echo -e "[i]: $key\t: ${PARAM_CLIENT_CONF_AA[$key]}"
    #done |sort -r
done
exit
