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

#########################################################################
#                                                                       #
# 1.) Set default settings.                                             #
#                                                                       #
# Declare variables and ensure binary absolute paths exists.            #
#                                                                       #
#########################################################################

#########################################################################
#                                                                       #
# 2.) Setup functions.                                                  #
#                                                                       #
#########################################################################

#########################################################################
#                                                                       #
# 3.) Read script config file.                                          #
#                                                                       #
# Read target path and clients folder and loop through each target's    #
# path and its sub-folders path (client folders).                       #
#                                                                       #
# Compile list of files and export into a temp file which contain list  #
# of files found for each client for later use.                         #
#                                                                       #
#########################################################################

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
# 3.) Read script config file.                                          #
# 4.) Perform file state checks.                                        #
# 5.) Perform file transfer.                                            #
# 6.) Mail transfer report.                                             #
#                                                                       #
#########################################################################
