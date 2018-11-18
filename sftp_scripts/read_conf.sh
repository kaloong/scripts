#!/bin/bash
#################################################################################
#                                                                               #
# Program name . . . . . . . . . . . . . . :   scp_filesync.sh                  #
# Program dependency . . . . . . . . . . . :   conf.d/*.conf                    #
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
PARAM_CONF_LIST=$(ls template.conf.d/*.conf)

PARAM_SIZE_CHECKER_SLEEP_TIME=2;
PARAM_DATE_LOG="$(date '+%Y-%m-%d %H:%M:%S')"
PARAM_DATE_LOG_LABEL="$(date '+%Y%m%d')"
PARAM_OLD_IFS=$IFS

PARAM_MAIL_SUBJECT="--- TRANSFER REPORT ---"
PARAM_MAIL_STATUS="UNKNOWN"
PARAM_MAIL_LIST="kaloong@localhost"

BIN_ECHO=/bin/echo
BIN_TOUCH=/bin/touch
BIN_RM=/bin/rm
BIN_SLEEP=/bin/sleep
BIN_GREP=/bin/grep
BIN_MKDIR=/bin/mkdir
BIN_MAILX=/bin/mailx


$BIN_MKDIR -p $(dirname $0)/logs


FILE_LOCKFILE=/tmp/read_conf.lock
FILE_SCRIPT_LOG_DIR=$(dirname $0)/logs
FILE_SCRIPT_LOG=$FILE_SCRIPT_LOG_DIR/$(basename $0).$PARAM_DATE_LOG_LABEL.log


#######################################################
#                                                     #
# Default settings.                                   #
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
    #$BIN_ECHO "[info:]"$_func_param_f
    IFS=":"
    while read -r name value
    do
        if [[ ! -z $name && ! -z $value ]]
        then
            # Remove leading and trailing whitespace.
            shopt -s extglob
            #temp_attribute="${line//[[:space:]]/}"
              #Trim whitespace front and back
            trimmed_name_front="${name%%*( )}"
            trimmed_name_back="${trimmed_name_front##*( )}"
            trimmed_value_front="${value%%*( )}"
            trimmed_value_back="${trimmed_value_front##*( )}"
            client_attribute_name=$trimmed_name_back
            client_attribute_value="${trimmed_value_back//[[:space:]]/_}"
            PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ $client_attribute_value == "" ]]
            then
                $BIN_ECHO -e "[err :] $PARAM_DATE_LOG Parameter $client_attribute_name is empty. Abort."
                exit
            fi
            if [[ ${client_attribute_name:0:1} =~ "#" || ${client_attribute_name:0:1} =~ " "  ]]
            then
                $BIN_ECHO -e "[info:] $PARAM_DATE_LOG Parameter $client_attribute_name has been commented out. Ignore line."
            else
                $BIN_ECHO -e "[info:] $PARAM_DATE_LOG Read $client_attribute_name. $client_attribute_value."
                ARRAY_CLIENT_CONF[$client_attribute_name]=$client_attribute_value
            fi
        fi
    done < $PARAM_FUNC_READ_FILE
    #Very import to unset IFS or any upcoming loops will fail.
    unset IFS
    return
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
        $BIN_ECHO -e "[xfer:] $PARAM_DATE_LOG └── DTransfer ${ARRAY_CLIENT_CONF[source_dir]}/$PARAM_TARGET_BASE_DIR to ${ARRAY_CLIENT_CONF[destination_dir]}/"
        if [[ $($BIN_ECHO $?) == 1 ]]
        then
          $BIN_ECHO -e "[err :] $PARAM_DATE_LOG Something went wrong during transfer."
          PARAM_MAIL_STATUS="ERRORED"
          return 1
        fi
          PARAM_MAIL_STATUS="SUCCESS"
        return 0
    fi
    if [[ -f $PARAM_TARGET ]]
    then
        $BIN_ECHO -e "[xfer:] $PARAM_DATE_LOG └── FTransfer ${ARRAY_CLIENT_CONF[source_dir]}/$PARAM_TARGET_BASE_FILE to ${ARRAY_CLIENT_CONF[destination_dir]}/"
        if [[ $($BIN_ECHO $?) == 1 ]]
        then
          $BIN_ECHO -e "[err :] $PARAM_DATE_LOG Something went wrong during transfer."
          PARAM_MAIL_STATUS="ERRORED"
          return 1
        fi
        PARAM_MAIL_STATUS="SUCCESS"
        return 0
    fi
    $BIN_ECHO -e "[err :] $PARAM_DATE_LOG Target is neither file or directory. Nothing is transferred."
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

    #if source_dir exists, list the directory
    client_source_dir=${ARRAY_CLIENT_CONF[source_dir]}

    if [[ -d $client_source_dir ]]
    then
        # check files in the current root directory only
        temp_file="$(find $client_source_dir -maxdepth 1)"
        for f in $temp_file; do
            PARAM_DATE_LOG=$(FUNC_GET_DATE)
            if [[ ! -d $f ]]
            then
                check_result=$(FUNC_SIZE_CHECKER $f)
                if [[ ${check_result^^} == "FALSE" ]]
                then
                    $BIN_ECHO -e "[info:] $PARAM_DATE_LOG $f is still transferring. Skip target(s)."
                    #Add to later
                else
                    $BIN_ECHO -e "[info:] $PARAM_DATE_LOG $f is ready to be transferred."
                    #or $BIN_ECHO -e "[info:] $f $($BIN_ECHO $?)"
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
                        $BIN_ECHO -e "[info:] $PARAM_DATE_LOG $f is still transferring. Skip target(s)."
                        BOOL_GO_TRANSFER=false
                        #Add to later
                    else
                        $BIN_ECHO -e "[info:] $PARAM_DATE_LOG $f is ready to be transferred."
                        #or $BIN_ECHO -e "[info:] $f $($BIN_ECHO $?)"
                    fi
                fi
            done
            if [[ ${BOOL_GO_TRANSFER^^} == "FALSE" ]]
            then
                $BIN_ECHO -e "[info:] $PARAM_DATE_LOG └── Some file(s) in $d are still transferring. Skip target(s)."
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
        $BIN_ECHO -e "[info:] $PARAM_DATE_LOG log_filename is not defined. Using $temp_log_filename."
        exec 2>> $temp_log_filename  1>> $temp_log_filename
    else
        $BIN_ECHO -e "[info:] $PARAM_DATE_LOG ${ARRAY_CLIENT_CONF[log_filename]} is defined."
        exec 2>> ${ARRAY_CLIENT_CONF[log_filename]}  1>> ${ARRAY_CLIENT_CONF[log_filename]}
    fi
    $BIN_ECHO -e "[info:] $PARAM_DATE_LOG $PARAM_LOGGING_HEADER"
    return 0
}


#########################################################################
#                                                                       #
# 6.) Mail transfer report.                                             #
# Send transfer report to Admin.                                        #
#                                                                       #
#########################################################################
function FUNC_MAIL_TRANSFER_LOG {
	if [[ -n ${PARAM_MAIL_LIST^^} ]]
	then
		$BIN_ECHO -e "[info:] Send mail $PARAM_MAIL_SUBJECT $PARAM_MAIL_STATUS to $PARAM_MAIL_LIST"
		#$BIN_MAILX -s "$PARAM_MAIL_SUBJECT $PARAM_MAIL_STATUS" $PARAM_MAIL_LIST
		#$BIN_MAILX -s "$PARAM_MAIL_SUBJECT $PARAM_MAIL_STATUS" $PARAM_MAIL_LIST < $FILE_RESULT_FILE
	else
		$BIN_ECHO -e "[info:] PARAM_MAIL_LIST is not set. No mail notification will be sent."
	fi
	return 0
}

##################
#                #
# Error logging. #
#                #
##################
set -o errtrace
set -o errexit
set -e
trap '$BIN_ECHO -e "[err :] "Error on $FUNCNAME."' ERR
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
    $BIN_ECHO -e "[info:] $PARAM_DATE_LOG $PARAM_LOGGING_FOOTER"
    exec 2>> $FILE_SCRIPT_LOG 1>> $FILE_SCRIPT_LOG
    #exec >/dev/tty
    return 0
}

function FUNC_SHOW_CMD_HELP {
	#######################################################################
	#                                                                     #
	# Display help when running from command line. User can specify       #
	# different options, in order to run the facility on an ad hoc bases. #
	#                                                                     #
	#######################################################################
	$BIN_ECHO -e "\nUsage:"
	$BIN_ECHO -e "------"
	$BIN_ECHO -e "Flags available are:"
	$BIN_ECHO -e "-f or --conf to config file. If not specify, ./conf.d/*.conf will be read."
	$BIN_ECHO -e "------"
	return 0
}

function FUNC_CHECK_LOCKFILE {
	######################################################
	#                                                    #
	# Check if there is another process already running. #
	#                                                    #
	######################################################
	if [[ -e $FILE_LOCKFILE ]]
	then
		$BIN_ECHO -e "[info:] $PARAM_DATE_LOG Lock file found. Please check processes and try again. Exit script."
		exit 1
	else
		$BIN_ECHO -e "[info:] $PARAM_DATE_LOG No lock file found."
		$BIN_TOUCH $FILE_LOCKFILE
		return 0
	fi
}


function FUNC_REMOVE_LOCKFILE {
	######################################################
	#                                                    #
	# If it get to this function, we would assume it has #
	# finished processing and safe to remove lock file.  #
	#                                                    #
	######################################################
	if [[ -e $FILE_LOCKFILE ]]
	then
		$BIN_ECHO -e "[info:] $PARAM_DATE_LOG Lock file found. Remove lock file."
		$BIN_RM $FILE_LOCKFILE >/dev/null 2>&1
	else
		$BIN_ECHO -e "[info:] $PARAM_DATE_LOG No lock file found."
	fi
	return 0
}

#########################################################################
#                                                                       #
# Main body.                                                            #
# ----------                                                            #
# Ensure all parameters are ok before proceding.                        #
#                                                                       #
# 1.) Set default settings.                                             #
# 2.) Setup functions.                                                  #
# 3.) Read script config files.                                         #
# 4.) Perform file state checks.                                        #
# 5.) Perform file transfer.                                            #
# 6.) Mail transfer report.                                             #
#                                                                       #
#########################################################################

#########################################################################
#                                                                       #
# 0.) Parse command line options.                                       #
#                                                                       #
#########################################################################
for i in "$@"; do
	case $i in
		-h|--help)
		  exec &> /dev/tty
		  $BIN_ECHO "[info:] Option Help triggered" >&2
		  FUNC_SHOW_CMD_HELP
		  exit 0
		  ;;
		-c=*|--conf=*)
		  PARAM_CLIENT_CONF="${i#*=}"
		  $BIN_ECHO -e "[info:] PARAM_CLIENT_CONF: $PARAM_CLIENT_CONF"
		  shift
		  ;;
		*)
		  exec &> /dev/tty
		  $BIN_ECHO "Option requires an argument." >&2
		  exit 1
		  ;;
	esac
done

#########################################################################
#                                                                       #
# 2.) If -c flag not specified, loop throught each config via function  #
#     function FUNC_READ_CONF.                                          #
#                                                                       #
########################################################################
if [[ ! -n $PARAM_CLIENT_CONF ]]
then
    FUNC_CHECK_LOCKFILE
    for f in $PARAM_CONF_LIST; do
        PARAM_DATE_LOG=$(FUNC_GET_DATE)
        typeset -A ARRAY_CLIENT_CONF
        $BIN_ECHO -e "\n[info:] $PARAM_DATE_LOG Read Client config files\t: $f"
        $BIN_ECHO -e "[info:] $PARAM_DATE_LOG $PARAM_PARSE_HEADER"
        FUNC_READ_CONF $f

        FUNC_START_CLIENT_LOG_FILE $f
        FUNC_INSPECT_SOURCE_DIR $f
        FUNC_STOP_CLIENT_LOG_FILE $f
        PARAM_DATE_LOG=$(FUNC_GET_DATE)
        $BIN_ECHO -e "[info:] $PARAM_DATE_LOG $PARAM_PARSE_FOOTER"
        unset -v ARRAY_CLIENT_CONF
    done
    FUNC_REMOVE_LOCKFILE
else
    PARAM_DATE_LOG=$(FUNC_GET_DATE)
    typeset -A ARRAY_CLIENT_CONF
    $BIN_ECHO -e "\n[info:] $PARAM_DATE_LOG Read Client config files\t: $PARAM_CLIENT_CONF"
    $BIN_ECHO -e "[info:] $PARAM_DATE_LOG $PARAM_PARSE_HEADER"
    FUNC_CHECK_LOCKFILE
    FUNC_READ_CONF $PARAM_CLIENT_CONF
    FUNC_START_CLIENT_LOG_FILE $PARAM_CLIENT_CONF
    FUNC_INSPECT_SOURCE_DIR $PARAM_CLIENT_CONF
    FUNC_STOP_CLIENT_LOG_FILE $PARAM_CLIENT_CONF
    FUNC_MAIL_TRANSFER_LOG
    PARAM_DATE_LOG=$(FUNC_GET_DATE)
    $BIN_ECHO -e "[info:] $PARAM_DATE_LOG $PARAM_PARSE_FOOTER"
    unset -v ARRAY_CLIENT_CONF

    FUNC_REMOVE_LOCKFILE
fi
exit 0
