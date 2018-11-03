#!/usr/bin/env bash

#################################################################################
#                                                                               #
# Program name . . . . . . . . . . . . . . :   my_script_template.sh            #
# Program dependency . . . . . . . . . . . :   my_script_template.dat           #
# Date . . . . . . . . . . . . . . . . . . :   03/11/2018                       #
#                                                                               #
# My script template description goes here.                                     #
#                                                                               #
# Modification History                                                          #
# 03/11/18 KT - First edition my_script_template.sh.                            #
#                                                                               #
#################################################################################

######################
#                    #
# Debug shell script #
#                    #
######################
#set -x

############################################
#                                          #
# 1.) Check if previous job is running.    #
#                                          #
# If previous job flag file exist then     #
# exit gracecfully.                        #
#                                          #
# If no previous job found, prepare        #
# evironment for tasks execution.          #
#                                          #
############################################
#$BIN_RM -f $FILE_AU_AUDIT_RESULT_FILE >/dev/null 2>&1

#######################################################
#                                                     #
# 0.) Set default settings.                           #
#                                                     #
# Declare variables and binary absolute paths.        #
#                                                     #
#######################################################

############################################
#                                          #
#                                          #
############################################

##################################################
#                                                #
# Main body.                                     #
# ----------                                     #
# Ensure all parameters are ok before proceding. #
# Perform audit log examinations.                #
# Mail audit report.                             #
#                                                #
##################################################
