#!/bin/env bash

#set -x

PARAM_SIZE_CHECKER_SLEEP_TIME=10;
BIN_ECHO=/bin/echo;

function FUNC_SIZE_CHECKER
{
        local TGT_F_BF=$(stat -c %s $PARAM_TARGET_FILE)
        sleep $PARAM_SIZE_CHECKER_SLEEP_TIME
        local TGT_F_AF=$(stat -c %s $PARAM_TARGET_FILE)

        if [ "$TGT_F_BF" -eq "$TGT_F_AF" ]; then
                $BIN_ECHO -e "True"
                return 0; #Return True
        else
                $BIN_ECHO -e "False"
                return 1; #Return False
        fi
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
        $BIN_ECHO -e "-t $PARAM_SLEEP_TIME will be used."
        $BIN_ECHO -e "-m ."
        $BIN_ECHO -e "\n"
        $BIN_ECHO -e "------"
        return 0
}

for i in "$@"; do
        case $i in
                -h|--help)
                  exec &> /dev/tty
                  $BIN_ECHO "[info:] Option Help triggered" >&2
                  FUNC_SHOW_CMD_HELP
                  exit 0
                  ;;
                -t=*|--sleep=*)
                  PARAM_SIZE_CHECKER_SLEEP_TIME="${i#*=}"
                  $BIN_ECHO -e "[info:] Sleep time set to: $PARAM_SIZE_CHECKER_SLEEP_TIME"
                  shift
                  ;;
                -f=*|--target=*)
                  PARAM_TARGET_FILE="${i#*=}"
                  $BIN_ECHO -e "[info:] Target file set to: $PARAM_TARGET_FILE"
                  FUNC_SIZE_CHECKER $PARAM_TARGET_FILE
                  shift
                  ;;
                *)
                  exec &> /dev/tty
                  $BIN_ECHO "Option requires an argument." >&2
                  exit 1
                  ;;
        esac
done
exit 0;
