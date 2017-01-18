#!/bin/bash
# Name:         s3://CLIENT-config/common-env/Bastion_Launch
# Description:  Launch Bastion server 

echo -e "Bastion_Launch STARTED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

# Check input parameters
if [[ $# -ne 1 ]]; then echo $0: usage: Bastion_Launch ENV; exit 1; fi
if [[ $1 != "uat" && $1 != "prod" ]]; then echo "Valid values for ENV are uat or prod"; exit 1; fi

# Assign Parameters
ENV=$1

# Assign Common Bastion Variables
AMI="ami-..."
KEYNM="CLIENT-bastion-keypair"
INSTTP="t2.micro"

# Assign Environment Specific Bastion Variables
if [[ $ENV == "prod" ]]; then 
SUBNET="..."
SECGRP="..."
INSTNM="PRODBastion"
NINM="PRODBastionNI"
NISECGRP="PRODBastionSG"
EIP="..."
else
SUBNET="subnet-..."
SECGRP="sg-..."
INSTNM="UATBastion"
NINM="UATBastionNI"
NISECGRP="UATBastionSG"
EIP="eipalloc-..."
fi

#Launch Bastion from AMI	
aws ec2 run-instances --image-id $AMI --count 1 --instance-type $INSTTP --key-name $KEYNM --associate-public-ip-address --security-group-ids $SECGRP --subnet-id $SUBNET
if [[ $? -ne 0 ]]; then echo "AWS RUN-INSTANCES Command FAILURE"; exit 1; fi

sleep 30s

#Get New Instance ID
EC2=`aws ec2 describe-instances --filters Name=subnet-id,Values=$SUBNET | grep InstanceId | awk '{print $2}' | cut -d',' -f1 | sed 's/"//g'`
if [[ $? -ne 0 ]]; then echo "AWS DESCRIBE-INSTANCES Command FAILURE"; exit 1; fi

#Name New Instance
aws ec2 create-tags --resources $EC2 --tags Key=Name,Value=$INSTNM
if [[ $? -ne 0 ]]; then echo "AWS CREATE-TAGS Command FAILURE"; exit 1; fi

# Get Network Interface from Environment
NTWINT=`aws ec2 describe-network-interfaces --filters Name=subnet-id,Values="$SUBNET" | grep NetworkInterfaceId | awk '{print $2}' | cut -d',' -f1 | sed 's/"//g'`
if [[ $? -ne 0 ]]; then echo "AWS describe-network-interfaces Command FAILURE"; exit 1; fi

# Name Network Interface 
aws ec2 create-tags --resources $NTWINT --tags Key=Name,Value=$NINM
if [[ $? -ne 0 ]]; then echo "AWS create-tags for Network Interface Command FAILURE"; exit 1; fi

sleep 15s

# Associate EIP	
aws ec2 associate-address --allocation-id $EIP --network-interface-id $NTWINT
if [[ $? -ne 0 ]]; then echo "AWS Associate EIP Command FAILURE"; exit 1; fi


echo -e "Bastion_Launch ENDED ON $(date +"%Y-%m-%d-%H:%M:%S")" >> ./AWS_Launch_logfile

exit 0
