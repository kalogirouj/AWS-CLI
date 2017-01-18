#!/bin/bash
# Name:         s3://CLIENT-config/ENV/ENV_WEB_Launch
# Description:  Launch Web server

echo -e "ENV_WEB_Launch STARTED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

./AWS_Launch.sh ENV webserver >> ./AWS_Launch_logfile

echo -e "ENV_WEB_Launch ENDED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

exit 0
