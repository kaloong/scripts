#!/bin/bash
#################################################################################
#                                                                               #
# Program name . . . . . . . . . . . . . . :   scp_filesync.sh                  #
# Program dependency . . . . . . . . . . . :   conf.d/*.confi                   #
# Date         . . . . . . . . . . . . . . :   03/11/2018                       #
#                                                                               #
# It is running every 5 minutes via root crontab.                               #
# The script will go through client sftp dropboxes and carry out checks for     #
# completed files and move the completed file to another folder.                #
#                                                                               #
# Modification History                                                          #
# 03/11/18 KT - First edition sc_filesync.sh.                                   #
# 03/11/18 KT -                                                                 #
#                                                                               #
#################################################################################
PARAM_CONF_LIST=$(ls template.conf.d/*)

PARAM_SIZE_CHECKER_SLEEP_TIME=2;
PARAM_DATE_LOG="$(date '+%Y-%m-%d %H:%M:%S')"
PARAM_DATE_LOG_LABEL="$(date '+%Y%m%d')"

BIN_ECHO=/bin/echo;
BIN_SLEEP=/bin/sleep;
BIN_GREP=/bin/grep;
BIN_MKDIR=/bin/mkdir;
$BIN_MKDIR -p $(dirname $0)/logs
FILE_SCRIPT_LOG_DIR=$(dirname $0)/logs
FILE_SCRIPT_LOG=$FILE_SCRIPT_LOG_DIR/$(basename $0).$PARAM_DATE_LOG_LABEL.log


#######################################################
#                                                     #
# Default settings.                                   #
# Data time must be specific in the following format. #
# Date: MM/DD/YYYY                                    #
# Time: HH:MM:SS                                      #
# Declare variables and command paths                 #
#                                                     #
#######################################################

PARAM_CLIENT_MAIL_LIST="kaloong@localhost"
PARAM_CLIENT_MAIL_STATUS="UNKNOWN"
PARAM_CLIENT_ACCESS_NOT_FOUND="--- No anomalous access found ---"
PARAM_CLIENT_MAIL_HOSTNAME="$(/bin/hostname)"
PARAM_CLIENT_MAIL_SUBJECT="$PARAM_CLIENT_MAIL_HOSTNAME Transfer report check:"
PARAM_CLIENT_MAIL_HEADER="--- $PARAM_CLIENT_MAIL_HOSTNAME: Transfer report $PARAM_DATE_LOG --- "
PARAM_CLIENT_MAIL_FOOTER="--- $PARAM_CLIENT_MAIL_HOSTNAME: Transfer report $PARAM_DATE_LOG ---"

PARAM_PARSE_HEADER="---------------------------------- Parsing starts ----------------------------------"
PARAM_PARSE_FOOTER="--------------------------------- Parsing finishes ----------------------------------"
PARAM_LOGGING_HEADER="---------------------------------- Logging starts ----------------------------------"
PARAM_LOGGING_FOOTER="--------------------------------- Logging finishes ----------------------------------"


#########################################################################
#                                                                       #
# 0.) Check if previous job is running.                                 #
#                                                                       #
# If previous job flag file exist then exit gracecfully.                #
#                                                                       #
# If no previous job can be found, then prepare script environment for  #
# tasks execution.                                                      #
#                                                                       #
#########################################################################
function FUNC_CHECK_EXISTING_JOB {

echo

}

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
function FUNC_GET_DATE {
     local PARAM_DATE_LOG="$(date '+%Y-%m-%d %H:%M:%S')"
     $BIN_ECHO -e $PARAM_DATE_LOG
     return 0
}

#########################################################################
#                                                                       #
# 3.) Read script PARAM_CLIENT_CONF_AA file.                            #
#                                                                       #
# Read target path and clients folder and loop through each target's    #
# path and its sub-folders path (client folders).                       #
#                                                                       #
# Compile list of files and export into a temp file which contain list  #
# of files found for each client for later use.                         #
#                                                                       #
# Read conf and save content in global conf associate array.            #
#                                                                       #
#########################################################################
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
            # Remove leading and trailing whitespace.
            shopt -s extglob
            temp_attribute_name=$($BIN_ECHO $line |cut -d ':' -f 1)
            temp_attribute_name=${temp_attribute_name##+([[:space:]])}
            client_attribute_name=${temp_attribute_name%%+([[:space:]])}
            client_attribute_name=${client_attribute_name//[[:space:]]/_}
            temp_attribute=$($BIN_ECHO $line |cut -d ':' -f 2-)
            temp_attribute=${temp_attribute##+([[:space:]])}
            client_attribute=${temp_attribute%%+([[:space:]])}
            client_attribute=${client_attribute//[[:space:]]/_}
            #temp_attribute="${line//[[:space:]]/}"
            PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ $client_attribute == "" ]]
            then
                $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG Parameter $client_attribute_name is empty. Abort."
                exit
            fi
            if [[ ${client_attribute_name:0:1} =~ "#" ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG Parameter $client_attribute_name has been commented out. Ignore line."
            else
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG Read $client_attribute_name. $client_attribute."
                ARRAY_CLIENT_CONF[$client_attribute_name]=$client_attribute
            fi
      fi
    done < $PARAM_FUNC_READ_FILE

    return
}

# Perform strict parameter checks with regex rules.
# This will ensure that parameters are clean.
function FUNC_CHECK_PARAMS {
    local PARAM_MISSING="FALSE"

    for client_attribute_name in  "${!ARRAY_CLIENT_CONF[@]}" ; do
        local PARAM_DATE_LOG=$(FUNC_GET_DATE)
        if [[ ${client_attribute_name^^} == "CLIENT_NAME" ]]
        then
            if [[ -n ${ARRAY_CLIENT_CONF[$client_attribute_name]} ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter exists"
            else
                $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG $client_attribute_name parameter does not exists."
                PARAM_MISSING="true"
            fi
            continue
        fi
        local PARAM_DATE_LOG=$(FUNC_GET_DATE)
        if [[ "${client_attribute_name^^}" == "SOURCE_USER" ]]
        then
            if [[ -n ${ARRAY_CLIENT_CONF[$client_attribute_name]} ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter exists"
            else
                $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG $client_attribute_name parameter does not exists."
                PARAM_MISSING="true"
            fi
            #Check if user exist
            if [[ $(id ${ARRAY_CLIENT_CONF[$client_attribute_name]} > /dev/null 2>&1 ; $BIN_ECHO $?) == 0 ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG local source user exists"
            else
                $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG local source user does not exists."
                PARAM_MISSING="true"
            fi
            continue
        fi
        if [[ "${client_attribute_name^^}" == "SOURCE_KEY" ]]
        then
            local PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ -f ${ARRAY_CLIENT_CONF[$client_attribute_name]} ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name file exists"
            else
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name file does not exists."
            fi
            continue
        fi
        if [[   "${client_attribute_name^^}" == "SOURCE_HOST" ]]
        then
            local PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ -n ${ARRAY_CLIENT_CONF[$client_attribute_name]} ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter exists"
            else
                $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG $client_attribute_name parameter does not exists."
                PARAM_MISSING="true"
            fi
            continue
        fi
        if [[   "${client_attribute_name^^}" == "SOURCE_DIR" ]]
        then
            local PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ -n ${ARRAY_CLIENT_CONF[$client_attribute_name]} ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter exists"
            else
                $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG $client_attribute_name parameter does not exists."
                PARAM_MISSING="true"
            fi
            continue
        fi
        if [[   "${client_attribute_name^^}" == "DESTINATION_USER" ]]
        then
            local PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ -n ${ARRAY_CLIENT_CONF[$client_attribute_name]} ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter exists"
            else
                $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG $client_attribute_name parameter does not exists."
                PARAM_MISSING="true"
            fi
            continue
        fi
        if [[   "${client_attribute_name^^}" == "DESTINATION_KEY" ]]
        then
            local PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ -n ${ARRAY_CLIENT_CONF[$client_attribute_name]} ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter exists"
            else
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name paramater does not exists"
            fi
            continue
        fi
        if [[   "${client_attribute_name^^}" == "DESTINATION_HOST" ]]
        then
            local PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ -n ${ARRAY_CLIENT_CONF[$client_attribute_name]} ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter exists"
            else
                $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG $client_attribute_name parameter does not exists."
                PARAM_MISSING="true"
            fi
            continue
        fi
        if [[   "${client_attribute_name^^}" == "DESTINATION_DIR" ]]
        then
            local PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ -n ${ARRAY_CLIENT_CONF[$client_attribute_name]} ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter exists"
            else
                $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG $client_attribute_name parameter does not exists."
                PARAM_MISSING="true"
            fi
            continue
        fi
        if [[   "${client_attribute_name^^}" == "LOG_FILENAME" ]]
        then
            local PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ -n ${ARRAY_CLIENT_CONF[$client_attribute_name]} ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter exists"
            else
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter does not exists"
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG Script continues."
            fi
            continue
        fi
        if [[   "${client_attribute_name^^}" == "LOG_FORMAT" ]]
        then
            local PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ -n ${ARRAY_CLIENT_CONF[$client_attribute_name]} ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter exists"
            else
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $client_attribute_name parameter does not exists"
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG Script continues."
            fi
            continue
        fi
    #done |sort -r
    done
    return
    # Must return 0. Anything other than 0 will end up with unexpected EOF error.
}

#########################################################################
#                                                                       #
# 5.) Perform file transfer.                                            #
#                                                                       #
# Loop through each file path from transfer list and transfer to target #
# path. Upon each transfer completion, append transfer info to mail a   #
# report and persistent transfer log.                                   #
#                                                                       #
#########################################################################
function FUNC_TRANSFER_FILE {
    local PARAM_TARGET=$1
    local PARAM_TARGET_BASE_DIR=$(basename $1)
    local PARAM_TARGET_BASE_FILE=$(basename $1)
    local PARAM_DATE_LOG=$(FUNC_GET_DATE)
    if [[ -d $PARAM_TARGET ]]
    then
        $BIN_ECHO -e "[-t-]: $PARAM_DATE_LOG └── DTransfer ${ARRAY_CLIENT_CONF[source_dir]}/$PARAM_TARGET_BASE_DIR to ${ARRAY_CLIENT_CONF[destination_dir]}/"
        if [[ $($BIN_ECHO $?) == 1 ]]
        then
          $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG Something went wrong during transfer."
          return 1
        fi
        return 0
    fi
    if [[ -f $PARAM_TARGET ]]
    then
        $BIN_ECHO -e "[-t-]: $PARAM_DATE_LOG └── FTransfer ${ARRAY_CLIENT_CONF[source_dir]}/$PARAM_TARGET_BASE_FILE to ${ARRAY_CLIENT_CONF[destination_dir]}/"
        if [[ $($BIN_ECHO $?) == 1 ]]
        then
          $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG Something went wrong during transfer."
          return 1
        fi
        return 0
    fi
    $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG Target is neither file or directory. Nothing is transferred."
    return 1
}
#########################################################################
#                                                                       #
# 4.) Perform file state checks.                                        #
#                                                                       #
# Loop through each file from temporary list and check its file state.  #
#                                                                       #
# If we detect a file size change on a file, then do nothing.           #
# (Do not add file path to transfer list. )                             #
#                                                                       #
# If we do not detect file size change, add file path to transfer list. #
#                                                                       #
#########################################################################
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
            PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ ! -d $f ]]
            then
                check_result=$(FUNC_SIZE_CHECKER $f)
                if [[ ${check_result^^} == "FALSE" ]]
                then
                    $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $f is still transferring. Skip target(s)."
                    #Add to later
                else
                    $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $f is ready to be transferred."
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
                PARAM_DATE_LOG=$(FUNC_GET_DATE)
                if [[ ! -d $f ]]
                then
                    check_result=$(FUNC_SIZE_CHECKER $f)
                    if [[ ${check_result^^} == "FALSE" ]]
                    then
                        $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $f is still transferring. Skip target(s)."
                        BOOL_GO_TRANSFER=false
                        #Add to later
                    else
                        $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $f is ready to be transferred."
                        #or $BIN_ECHO -e "[-i-]: $f $($BIN_ECHO $?)"
                    fi
                fi
            done
            if [[ ${BOOL_GO_TRANSFER^^} == "FALSE" ]]
            then
                $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG └── Some file(s) in $d are still transferring. Skip target(s)."
            else
                FUNC_TRANSFER_FILE $d
            fi
        done
    fi
    return 0
}

function FUNC_START_CLIENT_LOG_FILE {
    local temp_log_filename=""
    local PARAM_DATE_LOG=$(FUNC_GET_DATE)

    if [[ ! -n ${ARRAY_CLIENT_CONF[log_filename]} ]]
    then
        temp_log_filename="$FILE_SCRIPT_LOG_DIR/${ARRAY_CLIENT_CONF[client_name]}.$PARAM_DATE_LOG_LABEL.log"
        $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG log_filename is not defined. Using $temp_log_filename."
        exec 2>> $temp_log_filename  1>> $temp_log_filename
    else
        $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG ${ARRAY_CLIENT_CONF[log_filename]} is defined."
        exec 2>> ${ARRAY_CLIENT_CONF[log_filename]}  1>> ${ARRAY_CLIENT_CONF[log_filename]}
    fi
    $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $PARAM_LOGGING_HEADER"
    return 0
}


#########################################################################
#                                                                       #
# 6.) Mail transfer report.                                             #
# Send transfer report to Admin.                                        #
#                                                                       #
#########################################################################









function FUNC_ABORT_SCRIPT {
    set -x
    break
    local PARAM_DATE_LOG=$(FUNC_GET_DATE)
    $BIN_ECHO -e "[-e-]: $PARAM_DATE_LOG Abort script."
    exec >/dev/tty
    exit 1
}
##################
#                #
# Error logging. #
#                #
##################
set -o errtrace
set -o errexit
set -e
trap '$BIN_ECHO -e "[-e-]: "Error on $FUNCNAME."' ERR
#####################################################
#                                                   #
# Disable pipefail to prevent egrep from breaking.  #
# #set -o pipefail                                  #
#                                                   #
# Disable nounset as we need to unset               #
# ARRAY_CLIENT_CONF in every iteration.             #
# #set -o nounset                                   #
#                                                   #
# Disable debug to prevent log from being flooded.  #
# #set -x                                           #
#                                                   #
# Below, pipe stdout & stderr to $FILE_SCRIPT_LOG   #
# for debug purposes.                               #
#                                                   #
#####################################################
exec 2>> $FILE_SCRIPT_LOG 1>> $FILE_SCRIPT_LOG

function FUNC_STOP_CLIENT_LOG_FILE {
    local PARAM_DATE_LOG=$(FUNC_GET_DATE)
    $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $PARAM_LOGGING_FOOTER"
    exec 2>> $FILE_SCRIPT_LOG 1>> $FILE_SCRIPT_LOG
    #exec >/dev/tty
    return 0
}
#########################################################################
#                                                                       #
# Main body.                                                            #
# ----------                                                            #
# Ensure all parameters are ok before proceding.                        #
# Perform audit log examinations.                                       #
# 1.) Set default settings.                                             #
# 2.) Setup functions.                                                  #
# 3.) Read script client config files.                                  #
# 4.) Perform file state checks.                                        #
# 5.) Perform file transfer.                                            #
# 6.) Mail transfer report.                                             #
#                                                                       #
#########################################################################
#########################################################################
#                                                                       #
# 3.) Loop through each config file via function FUNC_READ_CONF, and    #
#                                                                       #
#########################################################################
#########################################################################
#                                                                       #
# 2.) Loop through each config file via function FUNC_READ_CONF, and    #
#                                                                       #
########################################################################
for f in $PARAM_CONF_LIST; do
    PARAM_DATE_LOG=$(FUNC_GET_DATE)
    typeset -A ARRAY_CLIENT_CONF
    $BIN_ECHO -e "\n[-i-]: $PARAM_DATE_LOG Read Client config files\t: $f"
    $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $PARAM_PARSE_HEADER"
    FUNC_READ_CONF $f
    # FUNC_CHECK_PARAMS is Pointless as it can't abort.
    #FUNC_CHECK_PARAMS $f
    FUNC_START_CLIENT_LOG_FILE $f
    FUNC_INSPECT_SOURCE_DIR $f
    FUNC_STOP_CLIENT_LOG_FILE $f
    PARAM_DATE_LOG=$(FUNC_GET_DATE)
    $BIN_ECHO -e "[-i-]: $PARAM_DATE_LOG $PARAM_PARSE_FOOTER"
    unset -v ARRAY_CLIENT_CONF
    #for key in  "${!ARRAY_CLIENT_CONF[@]}" ; do
    #    $BIN_ECHO -e "[-i-]: $key\t: ${ARRAY_CLIENT_CONF[$key]}"
    #done |sort -r
done
exit 0
