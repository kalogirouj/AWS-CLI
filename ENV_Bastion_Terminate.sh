#!/bin/bash
# Name:         s3://CLIENT-config/ENV/ENV_Bastion_Terminate
# Description:  Terminate Bastion server

echo -e "ENV_Bastion_Terminate STARTED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

./AWS_Bastion_Terminate.sh ENV >> ./AWS_Launch_logfile

echo -e "ENV_Bastion_Terminate ENDED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

exit 0
