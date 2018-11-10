#!/bin/bash

#set -x
typeset -A config
conf_list=$(ls conf.d/*)

function read_config {
        local func_param_f=$1
        echo "--lv1>:"$_func_param_f
        while read line
        do
          if  echo $line|grep -F : &>/dev/null
          then
                client_attribute=$(echo $line |cut -d ':' -f 1)
                config[$client_attribute]=$(echo $line|cut -d ':' -f 2-)
                echo "--lv2>:"${config[$client_attribute]}
          fi
        done < $func_param_f
}
for f in $conf_list; do
        read_config $f
done #done for
#
for f in $conf_list; do
for key in  "${!config[@]}" ; do
        echo -e "$key: ${config[$key]}"
done |sort -r
done < $f
exit
