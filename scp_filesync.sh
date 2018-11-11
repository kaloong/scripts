#!/usr/bin/env bash

#################################################################################
#                                                                               #
# Program name . . . . . . . . . . . . . . :   scp_filesync.sh                  #
# Program dependency . . . . . . . . . . . :   sco_client.dat                   #
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

######################
#                    #
# Debug shell script #
#                    #
######################
#set -x

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



}
#########################################################################
#                                                                       #
# 1.) Set default settings.                                             #
#                                                                       #
# Declare variables and ensure binary absolute paths exists.            #
#                                                                       #
#########################################################################
typeset -A PARAM_CLIENT_CONF_AA
PARAM_CONF_LIST=$(ls template.conf.d/*)
PARAM_SIZE_CHECKER_SLEEP_TIME=10;
BIN_ECHO=/bin/echo;


#########################################################################
#                                                                       #
# 2.) Setup functions.                                                  #
#                                                                       #
#########################################################################

#########################################################################
#                                                                       #
# 3.) Read script PARAM_CLIENT_CONF_AA file.                                          #
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
function FUNC_READ_CONF {
    local PARAM_FUNC_READ_FILE=$1
    #echo "[i]:"$_func_param_f
    while read line
    do
        if  $BIN_ECHO $line|grep -F : &>/dev/null
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
            #else
            #    #client_attribute_name=${temp_attribute_name//[[:blank:]]/}
            #    client_attribute_name=$temp_attribute_name
            #    client_attribute=$temp_attribute
            #    PARAM_CLIENT_CONF_AA[$client_attribute_name]=$client_attribute
            fi
        fi
    done < $PARAM_FUNC_READ_FILE
    return
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
function FUNC_LOOP_SOURCE_DIR {

echo

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

#########################################################################
#                                                                       #
# 6.) Mail transfer report.                                             #
# Send transfer report to Admin.                                        #
#                                                                       #
#########################################################################

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
for f in $PARAM_CONF_LIST; do
    echo -e "\n[i]: Read config file\t: $f"
    echo "[i]: ---------------------------------------------------------"
    FUNC_READ_CONF $f
    #for key in  "${!PARAM_CLIENT_CONF_AA[@]}" ; do
    #    echo -e "[i]: $key\t: ${PARAM_CLIENT_CONF_AA[$key]}"
    #done |sort -r
done

