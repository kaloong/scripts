#!/bin/bash
set -x
source functions.sh
echo -e "Start of cfg.sh"
for i in $(ls $PWD/*.ini); do
   shopt -s extglob
   dummy=$(basename $i)
   aa_name="${dummy//.ini/_aa}"
   declare -A "${aa_name}"=()
   echo -e "+++ $aa_name +++"
   aa_name["name"]="$i"
done
echo -e "...${aa_name[name]}..."
echo -e "...${cfg1_aa[name]}..."
echo -e "...${cfg2_aa[name]}..."
echo -e "...${cfg3_aa[name]}..."

echo -e "End of cfg.sh"
exit
