#!/bin/bash
# Name:         s3://CLIENT-config/ENV/ENV_Bastion_Rebuild
# Description:  Rebuild Bastion server

echo -e "ENV_Bastion_Rebuild STARTED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

./AWS_Bastion_Terminate.sh ENV >> ./AWS_Launch_logfile

sleep 120s

./AWS_Bastion_Launch.sh ENV >> ./AWS_Launch_logfile

echo -e "ENV_Bastion_Rebuild ENDED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

exit 0
