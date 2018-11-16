#!/bin/bash
#set -x
source functions.sh
function validate
{
  local f=$1
  echo -e "+++ ${f[name]}"
  return
}
echo -e "Start of cfg.sh"
index=0
for i in $(ls $PWD/*.ini); do
   shopt -s extglob
   declare -A cfg_files
   dummy=$(basename $i)
   declare aa_name="${dummy//.ini/_aa}"
   cfg_files[${index}]="$i"
   let index=${index}+1
   FUNC_VALIDATE_CFG_V0 ${aa_name} $i
done
#FUNC_VALIDATE_CFG ${cfg1_aa[name]}
#echo -e "Config AA is: ${cfg_files[0]}"
#echo -e "Config AA is: ${cfg_files[1]}"
echo -e "Config AA is: ${!cfg_files[@]}"
echo -e "Config AA is: ${aa_name[@]}"

echo -e "End of cfg.sh"
exit
