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

#######################################################
#                                                     #
# 0.) Set default settings.                           #
#                                                     #
# Declare variables and binary absolute paths.        #
#                                                     #
#######################################################

############################################
#                                          #
# 2.) Check if previous job is running.    #
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
