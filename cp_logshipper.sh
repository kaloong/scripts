#!/bin/bash
logfile=/usr/scripts/log_shipper.log
touch $logfile
exec > $logfile 2>&1
source /etc/profile.d/CP.sh
fwm logexport -i $FWDIR/log/fw.adtlog -o /usr/scripts/log_shipper.out -n -p
fw logswitch -audit
scp /usr/scripts/log_shipper.out xxx@xxx.xxx.xxx.xxx:/home/xxx/log_shipped/.
exit
