#!/bin/bash
# Name:         s3://CLIENT-config/common-env/Bastion_Terminate
# Description:  Terminate Bastion 

echo -e "Bastion_Terminate STARTED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

# Check input parameters
if [[ $# -ne 1 ]]; then echo $0: usage: Bastion_Terminate ENV; exit 1; fi
if [[ $1 != "uat" && $1 != "prod" ]]; then echo "Valid values for ENV are uat or prod"; exit 1; fi

# Assign Parameters
ENV=$1

# Assign Environment Specific Bastion Variables
if [[ $ENV == "prod" ]]; then 
SUBNET="subnet-...";
else
SUBNET="subnet-...";
fi

#Get Instance ID
EC2=`aws ec2 describe-instances --filters Name=subnet-id,Values=$SUBNET | grep InstanceId | awk '{print $2}' | cut -d',' -f1 | sed 's/"//g'`
if [[ $? -ne 0 ]]; then echo "AWS DESCRIBE-INSTANCES Command FAILURE"; exit 1; fi

#Terminate instance	
aws ec2 terminate-instances --instance-ids $EC2
if [[ $? -ne 0 ]]; then echo "AWS TERMINATE-INSTANCES Command FAILURE"; exit 1; fi

echo -e "Bastion_Terminate ENDED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

exit 0
