#!/bin/bash

function FUNC_VALIDATE_CFG {
    local cfg_file=$1
    source $cfg_file
    echo -e "---------------------"
    echo -e "Working on $cfg_file"
    echo -e "${CLIENT_USER}"
    echo -e "${CLIENT_PASS}"
    echo -e "${CLIENT_DB}"
    echo -e "---------------------"
    if  [[ "${CLIENT_USER^^}" == "CLIENT " || "${CLIENT_USER}" == "" ]]; then
        echo -e "[-] Found a fake user error on CLIENT_USER"
        exit 1
    fi
    if  [[ "${CLIENT_PASS^^}" == "PASSWORD5678" || "${CLIENT_PASS}" == "" ]]; then
        echo -e "[-] Found a fake pass error on CLIENT_PASS"
        exit 1
    fi
    return 0
}
