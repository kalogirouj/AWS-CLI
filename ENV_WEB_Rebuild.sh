#!/bin/bash
# Name:         s3://CLIENT-config/ENV/ENV_WEB_Rebuild
# Description:  Rebuild Web server 

echo -e "ENV_WEB_Rebuild STARTED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

./ENV_WEB_Terminate.sh >> ./AWS_Launch_logfile

sleep 120s

./AWS_Launch.sh ENV webserver >> ./AWS_Launch_logfile

echo -e "ENV_WEB_Rebuild ENDED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

exit 0
