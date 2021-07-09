#!/usr/bin/env bash

#################################################################################
#                                                                               #
# Program name . . . . . . . . . . . . . . :   au_audit_check.sh                #
# Program dependency . . . . . . . . . . . :   au_audit_filter.cfg              #
# Date         . . . . . . . . . . . . . . :   25/06/2018                       #
# It is running every day before 0600 via root crontab.                         #
# The script interrogates the auditlog and send a report to me via email.       #
#                                                                               #
# Modification History                                                          #
# 25/06/18 KT - First edition au_audit_check.sh.                                #
# 17/07/18 KT - Added command line parsing for ad hoc tasks.                    #
#             - Fixed date range specifications.                                #
#             - Added blank line detection and prevention for filter file.      #
#             - Rearranged the ausearch and aureport logic.                     #
#               Major logic change by using aureport with keyword first, then   #
#               extract event id and egrep the pathname of each event access,   #
#               then append the pathname back to the aureport.                  #
#             - Added help function and redirect to /dev/tty when run from      #
#               command line.                                                   #
#             - Updated PARAM_AU_AUDIT_MAIL_LIST                                #
# 22/11/18 KT - Move lock file from /usr/local/admin to /tmp                    #
#               Remove -f flag from remove lock file operation to make script   #
#               safer.                                                          #
# 16/10/19 KT - Added export timezone in order to reduce the amount of syscalls #
#               created by the script. Use strace to see it for yourself.       #
#                                                                               #
#    stat("/etc/localtime", {st_mode=S_IFREG|0644, st_size=3661, ...}_ =0       #
#                                                                               #
#            - Removed duplicate set -e as set -o errexit aldready exists.      #
#                                                                               #
#################################################################################

#############################################
#                                           #
# The most interesting part of the script.  #
# The question is: Is this an Optimisation  #
# or bugfix?                                #
#                                           #
# And would we see it elsewhere on other    #
# script?                                   #
#                                           #
#############################################
export TZ=:/etc/localtime

######################
#                    #
# Debug shell script #
#                    #
######################
#set -x

#######################################################
#                                                     #
# Default settings.                                   #
# Data time must be specific in the following format. #
# Date: MM/DD/YYYY                                    #
# Time: HH:MM:SS                                      #
# Declare variables and command paths                 #
#                                                     #
#######################################################
PARAM_START_DATE="$(date +%m/%d/%Y --date=yesterday)"
PARAM_END_DATE="$(date +%m/%d/%Y --date=today)"
PARAM_START_TIME=00:00:00 
PARAM_END_TIME=00:00:00

PARAM_AU_AUDIT_MAIL_LIST="kaloong@localhost"
PARAM_AU_AUDIT_MAIL_STATUS="UNKNOWN"
PARAM_AU_AUDIT_ACCESS_NOT_FOUND="--- No anomalous access found ---"
PARAM_AU_AUDIT_MAIL_HOSTNAME="$(/bin/hostname)"
PARAM_AU_AUDIT_MAIL_SUBJECT="$PARAM_AU_AUDIT_MAIL_HOSTNAME AU audit check:"
PARAM_AU_AUDIT_MAIL_HEADER="--- $PARAM_AU_AUDIT_MAIL_HOSTNAME: AU audit report $PARAM_START_DATE:$PARAM_START_TIME - $PARAM_END_DATE:$PARAM_END_TIME starts --- "
PARAM_AU_AUDIT_MAIL_FOOTER="--- $PARAM_AU_AUDIT_MAIL_HOSTNAME: AU audit report $PARAM_START_DATE:$PARAM_START_TIME - $PARAM_END_DATE:$PARAM_END_TIME ends ---"
PARAM_TMP_LINE_COUNT_TARGET=100
PARAM_TMP_LINE_COUNT_RESULT=0

##########################################################################
#                                                                        #
# The PARAM_AU_AUDIT_MAIL_LINE_1 is used as part of the search.          #
# So be careful.                                                         #
#                                                                        #
# Note: This script is designed to work with one keyword only.           # 
#     : We can look into improving it for multiple keywords in future.   # 
#                                                                        #
##########################################################################
PARAM_AU_AUDIT_MAIL_LINE_1="============================================================"
PARAM_AU_AUDIT_KEYWORD=au_audit

####################
#                  #
# Start off empty. #
#                  #
####################
PARAM_AU_AUDIT_EGREP_FILTER=

#FILE_AU_AUDIT_CFG=
FILE_AU_AUDIT_CFG=/home/adm/au_audit_check.cfg
FILE_AU_AUDIT_TMP=/home/adm/au_audit_check.tmp
FILE_AU_AUDIT_AUREPORT=/home/adm/au_audit_check.aureport
FILE_AU_AUDIT_RESULT_FILE=/home/adm/au_audit_check.out
FILE_AU_AUDIT_LOG=/home/adm/au_audit_check.log
FILE_AU_AUDIT_LOCK=/home/adm/au_audit_check.lock

BIN_AUDITCTL=/sbin/auditctl
BIN_AUSEARCH=/sbin/ausearch
BIN_AUREPORT=/sbin/aureport
BIN_HEAD=/usr/bin/head
BIN_TAIL=/usr/bin/tail
BIN_EGREP=/bin/egrep
BIN_MAILX=/bin/mailx
BIN_ECHO=/bin/echo
BIN_NICE=/bin/nice
BIN_RM=/bin/rm
BIN_AWK=/bin/awk
BIN_CAT=/bin/cat
BIN_WC=/usr/bin/wc
BIN_TOUCH=/bin/touch


#########################################################################################################################################
#                                                                                                                                       # 
# Default flags sections.                                                                                                               #
#                                                                                                                                       # 
# BOOL_AU_AUDIT_SEND_MAIL="True"  if you want to send the report via email.                                                             #
# BOOL_SHOW_CMD          ="True"  if you want to show command the command in log.                                                       #
# BOOL_SHOW_AUDITCTL     ="False" if you want to include the watched folder in the mail report. It is generated dinamically via         #
# 				  				  auditctl -l.                                                                                          #
# BOOL_SHOW_AUDIT_HELP   ="False" if you want to show see the inspect command line in log.                                              #
# BOOL_BINARY_CHECK      ="False" Check if all binary exist. Default is should be False.                                                #
# BOOL_PARAMETER_CHECK   ="False" Check if parameters exist and are set. Default is should be False.                                    #
# BOOL_MAILING_CHECK     ="False" Check if all the mail parameters are exists.                                                          #
#                                                                                                                                       #
#########################################################################################################################################

BOOL_AU_AUDIT_SEND_MAIL="True"
BOOL_SHOW_CMD="True"
BOOL_SHOW_AUDITCTL="False"
BOOL_SHOW_AUDIT_HELP="False"
BOOL_BINARY_CHECK="False"
BOOL_PARAMETER_CHECK="False"
BOOL_MAILING_CHECK="False"


############################################
#                                          #
# Clean up audit result report operations. #
#                                          #
############################################
$BIN_RM -f $FILE_AU_AUDIT_RESULT_FILE >/dev/null 2>&1


function FUNC_CHECK_PARAMS { 
	###################################################################
	#                                                                 #
	# Check if auditd mailing exists. BOOL_MAILING_CHECK False by     #
	# default. See default flags section.                             #
	#                                                                 #
	# Need to ensure parameters are type checked(Work in progress).   #
	# 19/07/2018 by KT.                                               #
	#                                                                 #
	###################################################################
	if [[ 	-n $PARAM_AU_AUDIT_MAIL_SUBJECT && \
	 	-n $PARAM_AU_AUDIT_MAIL_LIST && \
	 	-n $PARAM_AU_AUDIT_MAIL_STATUS && \
	 	-n $PARAM_AU_AUDIT_MAIL_HEADER && \
		-n $PARAM_AU_AUDIT_MAIL_FOOTER && \
		-n $PARAM_AU_AUDIT_ACCESS_NOT_FOUND && \
		-n $PARAM_AU_AUDIT_MAIL_HOSTNAME && \
		-n $PARAM_AU_AUDIT_MAIL_LINE_1 && \
		-n $PARAM_AU_AUDIT_MAIL_HOSTNAME && \
		-n $BOOL_AU_AUDIT_SEND_MAIL ]]
	then
		BOOL_MAILING_CHECK=True
	fi

	##############################################################
	#                                                            #
	# Check if the binary exists. BOOL_BINARY_CHECK False by     #
        # default. See default flags section.                        #
	#                                                            #
	##############################################################
	if [[ 	-x $BIN_AUDITCTL && \
		-x $BIN_AUSEARCH && \
		-x $BIN_AUREPORT && \
		-x $BIN_HEAD && \
		-x $BIN_TAIL && \
		-x $BIN_EGREP && \
		-x $BIN_MAILX && \
		-x $BIN_ECHO && \
		-x $BIN_NICE && \
		-x $BIN_RM && \
		-x $BIN_AWK && \
		-x $BIN_CAT && \
		-x $BIN_WC && \
		-x $BIN_TOUCH ]]
	then
		BOOL_BINARY_CHECK=True
	fi

	##################################################################
	#                                                                #
	# Check if auditd parameter exists. False by default.            #
	# No need to check if FILE_AU_AUDIT_LOG file is zero size.       #
	# No need to check if PARAM_AU_AUDIT_EGREP_FILTER file is empty. #
	#                                                                #
	# Need to ensure parameters are type checked(Work in progress).  #
	# 19/07/2018 by KT.                                              #
	#                                                                #
	##################################################################
	if [[ -n $PARAM_AU_AUDIT_KEYWORD && \
	      -n $PARAM_TMP_LINE_COUNT_TARGET && \
	      $PARAM_TMP_LINE_COUNT_TARGET =~ ^[0-9]+$ && \
	      $PARAM_TMP_LINE_COUNT_RESULT =~ ^[0-9]+$ && \
	      -n $PARAM_TMP_LINE_COUNT_RESULT && \
	      -n $FILE_AU_AUDIT_CFG && \
	      -e $FILE_AU_AUDIT_CFG && \
	      -n $FILE_AU_AUDIT_RESULT_FILE && \
	      -n $FILE_AU_AUDIT_TMP && \
	      -n $FILE_AU_AUDIT_AUREPORT && \
	      -n $FILE_AU_AUDIT_LOG && \
	      -z $PARAM_AU_AUDIT_EGREP_FILTER && \
	      ! -z $PARAM_AU_AUDIT_KEYWORD && \
	      ! -z $FILE_AU_AUDIT_RESULT_FILE ]]
	then
		BOOL_PARAMETER_CHECK=True
	fi

	$BIN_ECHO -e "[info:] BOOL_MAILING_CHECK is: $BOOL_MAILING_CHECK"
	$BIN_ECHO -e "[info:] BOOL_BINARY_CHECK is: $BOOL_BINARY_CHECK"
	$BIN_ECHO -e "[info:] BOOL_PARAMETER_CHECK is: $BOOL_PARAMETER_CHECK"

	##############################################################################
	#                                                                            #
	# Check if BOOL_BINARY_CHECK, BOOL_PARAMETER_CHECK, BOOL_MAILING_CHECK are   #
	# all set to True. If not, something might be wrong.                         #
	#                                                                            #
	##############################################################################
	if [[ ${BOOL_BINARY_CHECK^^} == "TRUE" && ${BOOL_PARAMETER_CHECK^^} == "TRUE" && ${BOOL_MAILING_CHECK^^} == "TRUE" ]]
	then
		$BIN_ECHO -e "[info:] Proceed to next stage."
	else
		$BIN_ECHO -e "[info:] Precheck failed. Please check configuration parameters. Exiting script."
		exit
	fi

	###################################################################################
	#                                                                                 #
	# Make newlines the only separator, and prepare adding filter for egrep.          #
	# Read the audit filter file and append it with a pipe sign | to                  #
	# PARAM_AU_AUDIT_EGREP_FILTER, and finishes it off with the last line.            #
	# E.g. filter1|filter2|filter3                                                    #
	#                                                                                 #
	# The if statement below, detects and remove empty line.                          #
	# The shell parameter expension strip out the trailing newline from line.         #
	#                                                                                 #
	###################################################################################
	IFS=$'\n'
	for line in $($BIN_HEAD -n-1 "$FILE_AU_AUDIT_CFG"); do
		if [[ ! -z "${line// }" ]]
		then
			PARAM_AU_AUDIT_EGREP_FILTER+="${line%%$'\n'*}|"
		fi
	done
	PARAM_AU_AUDIT_EGREP_FILTER+="$($BIN_TAIL -1 $FILE_AU_AUDIT_CFG)"

	###########################################
	#                                         #
	# Check if user wants to see the command. #
	#                                         #
	###########################################
	if [[ ${BOOL_SHOW_CMD^^} == "TRUE" ]]
	then
		$BIN_ECHO "[info:] Shows command: $BIN_NICE -n 19 $BIN_AUREPORT --input-logs -k -i --start $PARAM_START_DATE $PARAM_START_TIME --end $PARAM_END_DATE $PARAM_END_TIME | $BIN_NICE -n 19 $BIN_EGREP -v \"$PARAM_AU_AUDIT_EGREP_FILTER\""
	fi


	#########################################################
	#                                                       #
	# Check if filter file exists and extract filter files. #
	#                                                       #
	#########################################################
	if [[ -e $FILE_AU_AUDIT_CFG ]]
	then
		$BIN_ECHO -e "[info:] Read filter file"
	else
		$BIN_ECHO -e "[info:] It will never reach here. In case it reaches here. Filter does not exist. Exiting script."
		exit
	fi
	return 0
}

function FUNC_GENERATE_MAIL_HEADER {
	###############################
	#                             #
	# Constructing auditd report. #
	#                             #
	###############################
	$BIN_ECHO -e "$PARAM_AU_AUDIT_MAIL_HEADER" >> $FILE_AU_AUDIT_RESULT_FILE
	$BIN_ECHO -e "[info:] Auditlog report construction starts."

	if [[ ${BOOL_SHOW_AUDITCTL^^} == "TRUE" ]]
	then
		$BIN_ECHO -e "\nThe following folder are being watched:\n" >> $FILE_AU_AUDIT_RESULT_FILE
		$BIN_AUDITCTL -l | $BIN_AWK -F" " '{print $2}' >> $FILE_AU_AUDIT_RESULT_FILE
	fi

	##########################################################
	#                                                        #
	# Create custom mail header rather than using aureport's #
	# headings to append the extra pathname section.         #
	#                                                        #
	##########################################################
	if [[ $PARAM_TMP_LINE_COUNT_RESULT -lt $PARAM_TMP_LINE_COUNT_TARGET  ]]
	then
		$BIN_ECHO -e "\nFile Report*" >> $FILE_AU_AUDIT_RESULT_FILE
		$BIN_ECHO -e "$PARAM_AU_AUDIT_MAIL_LINE_1" >> $FILE_AU_AUDIT_RESULT_FILE
		$BIN_ECHO -e "# date time auditkey syscall success exe auid event pathname" >> $FILE_AU_AUDIT_RESULT_FILE
		$BIN_ECHO -e "$PARAM_AU_AUDIT_MAIL_LINE_1" >> $FILE_AU_AUDIT_RESULT_FILE
	else
		
		#######################################################################################
		#                                                                                     #
		# Report is bigger then PARAM_TMP_LINE_COUNT_TARGET. Use raw report headings instead. #
		#                                                                                     #
		# Adjust PARAM_AU_AUDIT_MAIL_LINE_1 to shorter so then grep can pick it up for        #
		# MAIL SUBJECT STATUS.                                                                #
		#                                                                                     #
		#######################################################################################
		PARAM_AU_AUDIT_MAIL_LINE_1="==============================================="
		$BIN_ECHO -e "\nThere are too many entries($PARAM_TMP_LINE_COUNT_RESULT) to parse by ausearch.\nDisplay without pathname.\n" >> $FILE_AU_AUDIT_RESULT_FILE
	fi
	return 0
}


function FUNC_CHECK_AUDITLOG {


	######################################################################################
	#                                                                                    #
	# First it runs an aureport and generate $FILE_AU_AUDIT_AUREPORT. It then search for # 
        # the aureport. It after tail -2 and finds <no events ....> then no need to progress #
	# further. See below an example of the output and why the tail -2 and not -1.        #
	#                                                                                    #
	# Sample output.                                                                     #
	# ***************************************************                                #
	# *                                                 *                                #
	# * Key Report                                      *                                #
	# * =============================================== *                                #
	# * # date time key success exe auid event          *                                #
	# * =============================================== *                                #
	# * <no events of interest were found>              *                                #
	# *                                                 *                                #
	# ***************************************************                                #
	#                                                                                    #
	# If it is not empty, it will tail the $FILE_AU_AUDIT_AUREPORT file and egrep.       #
	#                                                                                    #
	######################################################################################

	$BIN_NICE -n 19 $BIN_AUREPORT --input-logs -k -i --start $PARAM_START_DATE $PARAM_START_TIME --end $PARAM_END_DATE $PARAM_END_TIME > $FILE_AU_AUDIT_AUREPORT


	if [[ $( $BIN_TAIL -2 $FILE_AU_AUDIT_AUREPORT ) == "<no events of interest were found>" ]] 
	then 
		FUNC_GENERATE_MAIL_HEADER
		$BIN_ECHO -e "[info:] It's empty from this date/time ranges. Nothing to report." 
		$BIN_ECHO -e "$PARAM_AU_AUDIT_ACCESS_NOT_FOUND" >> $FILE_AU_AUDIT_RESULT_FILE
	else
		$BIN_NICE -n 19 $BIN_EGREP -v "$PARAM_AU_AUDIT_EGREP_FILTER" $FILE_AU_AUDIT_AUREPORT > $FILE_AU_AUDIT_TMP
		###########################################################################################################
		#                                                                                                         #                                
		# If there are more than 100 lines in $FILE_AU_AUDIT_TMP, then use $FILE_AU_AUDIT_TMP. No ausearch on     #                                              
		# individual event.                                                                                       #                                              
		#                                                                                                         #                                           
		###########################################################################################################
		PARAM_TMP_LINE_COUNT_RESULT=$($BIN_WC -l $FILE_AU_AUDIT_TMP| $BIN_AWK -F" " '{print $1}' )

		################################################################################################
		#                                                                                              #
		# PARAM_TMP_LINE_COUNT_RESULT should not be bigger then PARAM_TMP_LINE_COUNT_TARGET or it will #
		# take forever. Hence we will not enter the auresearch event resolver block for the pathname.  # 
		#                                                                                              #
		################################################################################################
		if [[ $PARAM_TMP_LINE_COUNT_RESULT -lt $PARAM_TMP_LINE_COUNT_TARGET  ]]
		then
			FUNC_GENERATE_MAIL_HEADER
			$BIN_ECHO -e "[info:] Under $PARAM_TMP_LINE_COUNT_TARGET lines($PARAM_TMP_LINE_COUNT_RESULT). Send custom report." 
			IFS=$'\n'
			###########################################################################################################
			#                                                                                                         #
			# Can I extract the line number more efficiently then this?                                               #                                         
			#                                                                                                         #                                         
			###########################################################################################################
			START_LINE=$($BIN_CAT -n $FILE_AU_AUDIT_TMP |$BIN_EGREP "==="|$BIN_TAIL -1 |$BIN_AWK '{print $1}')

			###########################################################################################################
			#                                                                                                         #                                        
			# Find === in line and add one as our start of line.                                                      #
			# Use aureport to create an audit temp file.                                                              #
			# Then extract date, time, event id from aureport, send to ausearch for inline processing one at a time   #
			# in order to extract breached target paths.                                                              #
			# Extract breached target paths and redirect the result with the original aureport line with the target   #
			# path into FILE_AU_AUDIT_RESULT_FILE.                                                                    #
			#                                                                                                         #                                      
			# WARNING NOTE:                                                                                           #                                     
			# This Double For loop plus ausearch individual event can add significant overhead to the entire process  #
			# if the list is Huge. We should consider not including the target pathname to remove this overhead.      #
			#                                                                                                         #                             
			###########################################################################################################

			for line in $($BIN_TAIL -n+$((START_LINE+1)) $FILE_AU_AUDIT_TMP); do
				line_date=$($BIN_ECHO $line| $BIN_AWK -F" " '{print $2}')
				line_time=$($BIN_ECHO $line| $BIN_AWK -F" " '{print $3}')
				line_event_id=$($BIN_ECHO $line| $BIN_AWK -F" " '{print $8}')
				line_path=""
				
				############################################################################################
				#                                                                                          #
				# ausearch -k au_audit --start 07/16/2018 02:00:10 --end 07/16/2018 02:00:10 -a 4491231 -i #
				#                                                                                          #
				############################################################################################
				line_result=$($BIN_AUSEARCH --input-logs -k au_audit --start $line_date $line_time --end $line_date $line_time  -a $line_event_id -i)
				for sub_line in $line_result; do
					if [[ $( $BIN_ECHO $sub_line | $BIN_AWK -F" " '{print $1}' ) == "type=PATH" ]]
					then
						#$BIN_ECHO -e "[i2]:$sub_line"
						#$BIN_ECHO -e "[i3]:$($BIN_ECHO $sub_line|$BIN_AWK -F" " '{print $6}')"
						line_path=$($BIN_ECHO $sub_line|$BIN_AWK -F" " '{print $6}' )
					fi
				done
				$BIN_ECHO "$line path$line_path" >> $FILE_AU_AUDIT_RESULT_FILE
			done
		else
			BOOL_SHOW_AUDITCTL="True"
			FUNC_GENERATE_MAIL_HEADER
			$BIN_ECHO -e "[info:] Over $PARAM_TMP_LINE_COUNT_TARGET lines($PARAM_TMP_LINE_COUNT_RESULT). Send raw aureport." 
			$BIN_CAT $FILE_AU_AUDIT_TMP >> $FILE_AU_AUDIT_RESULT_FILE
		fi
	fi

	##############################################################################################
 	#                                                                                            # 
 	# MAIL STATUS CHECK:                                                                         # 
	# If after egrep, all we have left is the "===..." aka PARAM_AU_AUDIT_MAIL_LINE_1 or find    #
        # PARAM_AU_AUDIT_ACCESS_NOT_FOUND in the last line, we can change PARAM_AU_AUDIT_MAIL_STATUS #
	# to *NO ACCESS* and pipe PARAM_AU_AUDIT_ACCESS_NOT_FOUND into FILE_AU_AUDIT_RESULT_FILE.    #
        # Otherwise change the mail status and pipe the result accordingly.                          #
 	#                                                                                            #
	##############################################################################################
	
	if [[ $( $BIN_TAIL -1 $FILE_AU_AUDIT_RESULT_FILE ) == $PARAM_AU_AUDIT_MAIL_LINE_1 || $( $BIN_TAIL -1 $FILE_AU_AUDIT_RESULT_FILE ) == $PARAM_AU_AUDIT_ACCESS_NOT_FOUND ]] 
	then
		PARAM_AU_AUDIT_MAIL_STATUS="*NO ACCESS*"
	fi

	if [[ $( $BIN_TAIL -1 $FILE_AU_AUDIT_RESULT_FILE ) == $PARAM_AU_AUDIT_MAIL_LINE_1 ]] 
	then
		$BIN_ECHO -e "$PARAM_AU_AUDIT_ACCESS_NOT_FOUND" >> $FILE_AU_AUDIT_RESULT_FILE
	fi

	if [[ $( $BIN_TAIL -1 $FILE_AU_AUDIT_RESULT_FILE ) != $PARAM_AU_AUDIT_ACCESS_NOT_FOUND ]] 
	then
		PARAM_AU_AUDIT_MAIL_STATUS="*ACCESS FOUND*"
	fi
	$BIN_ECHO -e "" >> $FILE_AU_AUDIT_RESULT_FILE
	$BIN_ECHO -e "$PARAM_AU_AUDIT_MAIL_FOOTER" >> $FILE_AU_AUDIT_RESULT_FILE
	$BIN_ECHO -e "[info:] Auditlog report construction ends."

	if [[ ${BOOL_SHOW_AUDIT_HELP^^} == "TRUE" ]]
	then
		$BIN_ECHO "[info:] To inspect event : $BIN_AUSEARCH --input-logs -k $PARAM_AU_AUDIT_KEYWORD -i --start $PARAM_START_DATE $PARAM_START_TIME --end $PARAM_END_DATE $PARAM_END_TIME -a \"<EVENT_ID>\""
	fi
	return 0
}


function FUNC_MAIL_AUDITLOG {
	#########################################################
	#                                                       #
	# Send email if BOOL_AU_AUDIT_SEND_MAIL is set to True. #
	#                                                       #
	#########################################################
	if [[ ${BOOL_AU_AUDIT_SEND_MAIL^^} == "TRUE" ]]
	then
		$BIN_MAILX -s "$PARAM_AU_AUDIT_MAIL_SUBJECT $PARAM_AU_AUDIT_MAIL_STATUS" $PARAM_AU_AUDIT_MAIL_LIST < $FILE_AU_AUDIT_RESULT_FILE
	else
		$BIN_ECHO -e "[info:] BOOL_AU_AUDIT_SEND_MAIL is set to $BOOL_AU_AUDIT_SEND_MAIL. Hence no mail is sent."
	fi
	return 0
}


function FUNC_SHOW_CMD_HELP {
	#######################################################################
	#                                                                     #
	# Display help when running from command line. User can specify       #
	# different options, in order to run the facility on an ad hoc basis. #
	#                                                                     #
	#######################################################################
	$BIN_ECHO -e "\nUsage:"
	$BIN_ECHO -e "------"
	$BIN_ECHO -e "Flags available are:"
	$BIN_ECHO -e "-sd or --start-date to specific date range in mm/dd/yyyy format. If not specify, $PARAM_START_DATE will be used."
	$BIN_ECHO -e "-st or --start-time to specific time range in hh/mm/ss format. If not specify, $PARAM_START_TIME will be used."
	$BIN_ECHO -e "-ed or --end-date to specific date range in mm/dd/yyyy format. If not specify, $PARAM_END_DATE will be used."
	$BIN_ECHO -e "-et or --end-time to specific time range in hh/mm/ss format. If not specify, $PARAM_END_TIME will be used."
	$BIN_ECHO -e "-m or --mailto to specific email recipients. If not specify, $PARAM_AU_AUDIT_MAIL_LIST will be used."
	$BIN_ECHO -e "\nFor example:"
	$BIN_ECHO -e "------"
	$BIN_ECHO -e "au_audit_check.sh -sd=07/17/2018 -st=09:01:00 -ed=07/17/2018 -et=09:02:00 -m=kaloong1@localhost,kaloong2@localhost\n"
	return 0
}


function FUNC_CHECK_LOCKFILE {
	######################################################
	#                                                    #
	# Check if there is another process already running. #
	#                                                    #
	######################################################
	if [[ -e $FILE_AU_AUDIT_LOCK ]] 
	then
		$BIN_ECHO -e "[info:] Lock file found. Ensure no ausearch or aureport running before removing $FILE_AU_AUDIT_LOCK manually. Exit script."
		exit 1
	else
		$BIN_ECHO -e "[info:] No lock file found."
		$BIN_TOUCH $FILE_AU_AUDIT_LOCK
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
	if [[ -e $FILE_AU_AUDIT_LOCK ]] 
	then
		$BIN_ECHO -e "[info:] Lock file found. Remove lock file."
		$BIN_RM $FILE_AU_AUDIT_LOCK >/dev/null 2>&1
	else
		$BIN_ECHO -e "[info:] No lock file found."
	fi
	return 0
}

##################
#                #
# Error logging. #
#                #
##################
set -e
set -o errtrace
set -o nounset
set -o errexit
#####################################################
#                                                   #
# Disable pipefail to prevent egrep from breaking.  #
# set -o pipefail                                   #
#                                                   #
# Below, pipe stdout & stderr to $FILE_AU_AUDIT_LOG #
# for debug purposes.                               #
#                                                   #
#####################################################
exec 2> $FILE_AU_AUDIT_LOG 1> $FILE_AU_AUDIT_LOG


###############################
#                             #
# Parse command line options. #
#                             #
###############################
for i in "$@"; do 
	case $i in
		-t|--test)
		  exec &> /dev/tty
		  $BIN_ECHO "[info:] Option Test parameter triggered, Parameter: $i" >&2
		  FUNC_CHECK_PARAMS
		  exit 0
		  ;;
		-h|--help)
		  exec &> /dev/tty
		  $BIN_ECHO "[info:] Option Help triggered" >&2
		  FUNC_SHOW_CMD_HELP
		  exit 0
		  ;;
		-sd=*|--start-date=*)
		  PARAM_START_DATE="${i#*=}"
		  $BIN_ECHO -e "[info:] PARAM_START_DATE: $PARAM_START_DATE"
		  shift
		  ;;
		-st=*|--start-time=*)
		  PARAM_START_TIME="${i#*=}"
		  $BIN_ECHO -e "[info:] PARAM_START_TIME: $PARAM_START_TIME"
		  shift
		  ;;
		-ed=*|--end-date=*)
		  PARAM_END_DATE="${i#*=}"
		  $BIN_ECHO -e "[info:] PARAM_END_DATE: $PARAM_END_DATE"
		  shift
		  ;;
		-et=*|--end-time=*)
		  PARAM_END_TIME="${i#*=}"
		  $BIN_ECHO -e "[info:] PARAM_END_TIME: $PARAM_END_TIME"
		  shift
		  ;;
		-m=*|--mailto=*)
		  PARAM_AU_AUDIT_MAIL_LIST="${i#*=}"
		  BOOL_AU_AUDIT_SEND_MAIL=True
		  $BIN_ECHO -e "[info:] Mail to: $PARAM_AU_AUDIT_MAIL_LIST"
		  $BIN_ECHO -e "[info:] Mail flag: $BOOL_AU_AUDIT_SEND_MAIL"
		  shift
		  ;;
		*)
		  exec &> /dev/tty
		  $BIN_ECHO "Option requires an argument." >&2
		  exit 1
		  ;;
	esac
done

##################################################
#                                                #
# Main body.                                     #
# ----------                                     #
# Ensure all parameters are ok before proceding. # 
# Perform audit log examinations.                #
# Mail audit report.                             #
#                                                #
##################################################
FUNC_CHECK_LOCKFILE
FUNC_CHECK_PARAMS
FUNC_CHECK_AUDITLOG
FUNC_MAIL_AUDITLOG
FUNC_REMOVE_LOCKFILE

exit 0
