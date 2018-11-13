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
    #echo -e "[T]: └── Transfer $param_target_file from $param_target_dir to ${PARAM_CLIENT_CONF_AA[destination_dir]}/$param_target_base_dir"
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
        # check files in the current root directory only
        temp_file=$(find $client_source_dir -maxdepth 1)
        for f in $temp_file; do
            if [[ ! -d $f ]]
            then
                dname=$(dirname $f)
                fname=$(basename $f)
                check_result=$(FUNC_SIZE_CHECKER $f)
                if [[ ${check_result^^} == "FALSE" ]]
                then
                    echo -e "[i]: $f is still transferring. Try back again."
                    #Add to later
                else
                    echo -e "[i]: $f is ready to be transferred."
                    #or echo -e "[i]: $f $(echo $?)"
                    FUNC_TRANSFER_FILE $dname $fname
                fi
            fi
        done
        # check files within level 2 subdirectories and only transfer if every files are ready within.
        temp_dir=$(find $client_source_dir -mindepth 1 -maxdepth 1 -type d)
        for d in $temp_dir; do
            BOOL_GO_TRANSFER=true
            temp_file=$(find $d )
            for f in $temp_file; do
                if [[ ! -d $f ]]
                then
                    check_result=$(FUNC_SIZE_CHECKER $f)
                    if [[ ${check_result^^} == "FALSE" ]]
                    then
                        echo -e "[i]: $f is still transferring. Try back again."
                        BOOL_GO_TRANSFER=false
                        #Add to later
                    else
                        echo -e "[i]: $f is ready to be transferred."
                        #or echo -e "[i]: $f $(echo $?)"
                    fi
                fi
            done
            dname=$(dirname $d)
            fname=$(basename $d)
            if [[ ${BOOL_GO_TRANSFER^^} == "FALSE" ]]
            then
                echo -e "[i]: Some file(s) in $d are still transferring. Try back again."
            else
                FUNC_TRANSFER_FILE $d $fname
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
