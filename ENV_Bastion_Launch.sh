#!/bin/bash
# Name:         s3://CLIENT-config/ENV/ENV_Bastion_Launch
# Description:  Launch Bastion server

echo -e "ENV_Bastion_Launch STARTED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

./AWS_Bastion_Launch.sh ENV >> ./AWS_Launch_logfile

echo -e "ENV_Bastion_Launch ENDED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

exit 0
