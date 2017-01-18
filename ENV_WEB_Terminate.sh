#!/bin/bash
# Name:         s3://CLIENT-config/ENV/ENV_WEB_Terminate
# Description:  Terminate Web server

echo -e "ENV_WEB_Terminate STARTED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

# Assign Web AutoScale Variables
ASNM="ENVwebASG"

# Assign Web Launch Config Variables
LCGNM="ENVwebLaunchConfig"

# AutoScaling	
aws autoscaling delete-auto-scaling-group --force-delete --auto-scaling-group-name $ASNM
if [[ $? -ne 0 ]]; then echo "AWS delete-auto-scaling-group Command FAILURE"; exit 1; fi

sleep 5s

# Launch Config	
aws autoscaling delete-launch-configuration --launch-configuration-name $LCGNM 
if [[ $? -ne 0 ]]; then echo "AWS delete-launch-configuration Command FAILURE"; exit 1; fi 

echo -e "ENV_WEB_Terminate ENDED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

exit 0
