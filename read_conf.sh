#!/bin/bash

#set -x
PARAM_CONF_LIST=$(ls template.conf.d/*)

PARAM_SIZE_CHECKER_SLEEP_TIME=2;


BIN_ECHO=/bin/echo;
BIN_SLEEP=/bin/sleep;
BIN_GREP=/bin/grep;
BIN_MKDIR=/bin/mkdir;
$BIN_MKDIR -p $(dirname $0)/logs
FILE_APP_LOG_DIR=$(dirname $0)/logs
FILE_APP_LOG=$FILE_APP_LOG_DIR/$(basename $0).log


#######################################################
#                                                     #
# Default settings.                                   #
# Data time must be specific in the following format. #
# Date: MM/DD/YYYY                                    #
# Time: HH:MM:SS                                      #
# Declare variables and command paths                 #
#                                                     #
#######################################################
PARAM_DATE="$(date '+%Y-%m-%d %H:%M:%S')"

PARAM_CLIENT_MAIL_LIST="kaloong@localhost"
PARAM_CLIENT_MAIL_STATUS="UNKNOWN"
PARAM_CLIENT_ACCESS_NOT_FOUND="--- No anomalous access found ---"
PARAM_CLIENT_MAIL_HOSTNAME="$(/bin/hostname)"
PARAM_CLIENT_MAIL_SUBJECT="$PARAM_CLIENT_MAIL_HOSTNAME Transfer report check:"
PARAM_CLIENT_MAIL_HEADER="--- $PARAM_CLIENT_MAIL_HOSTNAME: Transfer report $PARAM_DATE --- "
PARAM_CLIENT_MAIL_FOOTER="--- $PARAM_CLIENT_MAIL_HOSTNAME: Transfer report $PARAM_DATE ---"

PARAM_APP_STARTS_HEADER="------------------------ APP STARTS ----------------------------------"
PARAM_APP_FINISHES_FOOTER="----------------------- APP FINISHES ----------------------------------"
PARAM_LOG_STARTS_HEADER="------------------------ LOG STARTS ----------------------------------"
PARAM_LOG_FINISHES_FOOTER="----------------------- LOG FINISHES ----------------------------------"

##################################
#                                #
# Generic size checker function. #
#                                #
##################################
function FUNC_SIZE_CHECKER {

    #$BIN_ECHO -e "[+]: $1"
    local TGT_F_BF=$(stat -c %s $1)
    $BIN_SLEEP $PARAM_SIZE_CHECKER_SLEEP_TIME
    local TGT_F_AF=$(stat -c %s $1)

    if [ "$TGT_F_BF" -eq "$TGT_F_AF" ]; then
            $BIN_ECHO -e "True"
            return 0; #Return True
    else
            $BIN_ECHO -e "False"
            return 1; #Return False
    fi
}


##################################################
#                                                #
# Generic read conf to associate array function. #
#                                                #
##################################################
function FUNC_READ_CONF {
    local PARAM_FUNC_READ_FILE=$1
    #$BIN_ECHO "[-i-]:"$_func_param_f
    while read line
    do
      if  $BIN_ECHO $line|$BIN_GREP -F : &>/dev/null
      then
            # Remove leading trailing whitespace.
            shopt -s extglob
            temp_attribute_name=$($BIN_ECHO $line |cut -d ':' -f 1)
            temp_attribute_name=${temp_attribute_name##+([[:space:]])}
            client_attribute_name=${temp_attribute_name%%+([[:space:]])}
            temp_attribute=$($BIN_ECHO $line |cut -d ':' -f 2-)
            temp_attribute=${temp_attribute##+([[:space:]])}
            client_attribute=${temp_attribute%%+([[:space:]])}
            #temp_attribute="${line//[[:space:]]/}"
            PARAM_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
            if [[ $client_attribute == "" ]]
            then
                $BIN_ECHO -e "[-e-]: $PARAM_DATE Parameter $client_attribute_name is empty. Abort."
                exit 1
            fi
            if [[ ${client_attribute_name:0:1} =~ "#" ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE Parameter $client_attribute_name has been commented out. Ignore line."
            else
                $BIN_ECHO -e "[-i-]: $PARAM_DATE Read $client_attribute_name."
                ARRAY_CLIENT_CONF[$client_attribute_name]=$client_attribute
            fi
      fi
    done < $PARAM_FUNC_READ_FILE

    return
}

function FUNC_TRANSFER_FILE {
    local PARAM_TARGET=$1
    local PARAM_TARGET_BASE_DIR=$(basename $1)
    local PARAM_TARGET_BASE_FILE=$(basename $1)
    $BIN_ECHO -e "---"
    PARAM_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
    if [[ -d $PARAM_TARGET ]]
    then
        $BIN_ECHO -e "[-t-]: $PARAM_DATE └── Transfer ${ARRAY_CLIENT_CONF[source_dir]}/$PARAM_TARGET_BASE_DIR to ${ARRAY_CLIENT_CONF[destination_dir]}/"
        if [[ $($BIN_ECHO $?) == 1 ]]
        then
          $BIN_ECHO -e "[-e-]: $PARAM_DATE Something went wrong during transfer."
          return 1
        fi
        $BIN_ECHO -e "---"
        return 0
    fi
    if [[ -f $PARAM_TARGET ]]
    then
        $BIN_ECHO -e "[-t-]: $PARAM_DATE └── Transfer ${ARRAY_CLIENT_CONF[source_dir]}/$PARAM_TARGET_BASE_FILE to ${ARRAY_CLIENT_CONF[destination_dir]}/"
        if [[ $($BIN_ECHO $?) == 1 ]]
        then
          $BIN_ECHO -e "[-e-]: $PARAM_DATE Something went wrong during transfer."
          return 1
        fi
        $BIN_ECHO -e "---"
        return 0
    fi
    $BIN_ECHO -e "[-e-]: $PARAM_DATE Target is neither file or directory. Nothing is transferred."
    return 1
}
function FUNC_INSPECT_SOURCE_DIR {

    #$BIN_ECHO -e "${ARRAY_CLIENT_CONF[@]}."
    #$BIN_ECHO -e "${!ARRAY_CLIENT_CONF[@]}."
    #$BIN_ECHO -e "[-i-]: ${ARRAY_CLIENT_CONF[source_dir]}."
    #if source_dir exists, list the directory
    client_source_dir=${ARRAY_CLIENT_CONF[source_dir]}

    if [[ -d $client_source_dir ]]
    then
        # check files in the current root directory only
        temp_file=$(find $client_source_dir -maxdepth 1)
        for f in $temp_file; do
            PARAM_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
            if [[ ! -d $f ]]
            then
                check_result=$(FUNC_SIZE_CHECKER $f)
                if [[ ${check_result^^} == "FALSE" ]]
                then
                    $BIN_ECHO -e "[-i-]: $PARAM_DATE $f is still transferring. Try back again."
                    #Add to later
                else
                    $BIN_ECHO -e "[-i-]: $PARAM_DATE $f is ready to be transferred."
                    #or $BIN_ECHO -e "[-i-]: $f $($BIN_ECHO $?)"
                    FUNC_TRANSFER_FILE $f
                fi
            fi
        done
        # check files within level 2 subdirectories and only transfer if every files are ready within.
        temp_dir=$(find $client_source_dir -mindepth 1 -maxdepth 1 -type d)
        for d in $temp_dir; do
            BOOL_GO_TRANSFER=true
            temp_file=$(find $d )
            for f in $temp_file; do
                PARAM_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
                if [[ ! -d $f ]]
                then
                    check_result=$(FUNC_SIZE_CHECKER $f)
                    if [[ ${check_result^^} == "FALSE" ]]
                    then
                        $BIN_ECHO -e "[-i-]: $PARAM_DATE $f is still transferring. Try back again."
                        BOOL_GO_TRANSFER=false
                        #Add to later
                    else
                        $BIN_ECHO -e "[-i-]: $PARAM_DATE $f is ready to be transferred."
                        #or $BIN_ECHO -e "[-i-]: $f $($BIN_ECHO $?)"
                    fi
                fi
            done
            if [[ ${BOOL_GO_TRANSFER^^} == "FALSE" ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE Some file(s) in $d are still transferring. Try back again."
            else
                FUNC_TRANSFER_FILE $d
            fi
        done
    fi
    return 0
}

function FUNC_START_CLIENT_LOG_FILE {
    temp_log_filename=""
    PARAM_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
    if [[ ! -n ${ARRAY_CLIENT_CONF[log_filename]} ]]
    then
        temp_log_filename="$FILE_APP_LOG_DIR/${ARRAY_CLIENT_CONF[client_name]}.log"
        $BIN_ECHO -e "[-i-]: $PARAM_DATE log_filename is not defined. Using $temp_log_filename."
        exec 2>> $temp_log_filename  1>> $temp_log_filename
    else
        $BIN_ECHO -e "[-i-]: $PARAM_DATE ${ARRAY_CLIENT_CONF[log_filename]} is defined."
        exec 2>> ${ARRAY_CLIENT_CONF[log_filename]}  1>> ${ARRAY_CLIENT_CONF[log_filename]}
    fi
    $BIN_ECHO -e "[-i-]: $PARAM_DATE $PARAM_LOG_STARTS_HEADER"
    return 0
}

function FUNC_STOP_CLIENT_LOG_FILE {
    PARAM_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
    $BIN_ECHO -e "[-i-]: $PARAM_DATE $PARAM_LOG_FINISHES_FOOTER"
    exec 2>> $FILE_APP_LOG 1>> $FILE_APP_LOG
    #exec >/dev/tty
    return 0
}

exec 2> $FILE_APP_LOG 1> $FILE_APP_LOG
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
    PARAM_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
    typeset -A ARRAY_CLIENT_CONF
    $BIN_ECHO -e "\n[-i-]: $PARAM_DATE Read Client config files\t: $f"
    $BIN_ECHO -e "[-i-]: $PARAM_DATE $PARAM_APP_STARTS_HEADER"
    FUNC_READ_CONF $f
    FUNC_START_CLIENT_LOG_FILE $f
    FUNC_INSPECT_SOURCE_DIR $f
    FUNC_STOP_CLIENT_LOG_FILE $f
    $BIN_ECHO -e "[-i-]: $PARAM_DATE $PARAM_APP_FINISHES_FOOTER"
    unset ARRAY_CLIENT_CONF
    #for key in  "${!ARRAY_CLIENT_CONF[@]}" ; do
    #    $BIN_ECHO -e "[-i-]: $key\t: ${ARRAY_CLIENT_CONF[$key]}"
    #done |sort -r
done
exit
