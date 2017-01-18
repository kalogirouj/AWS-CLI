#!/bin/bash
# Name:         s3://CLIENT-config/common-env/AWS_Launch
# Description:  Launch Web and App servers using AutoScale

# Two Parameters expected 
#   1 ENV	= Runtime Environment for this server (uat,prod)
#   2 ROLE	= The role for this particular server (webserver,appserver)
#   *** appserver ONLY ***
#   3 ASGGROUP  = AutoScale group to run clients
#   4 CLIENTS   = Clients to run on this appserver

# Assign Parameters
ENV=$1
ROLE=$2
ASGGROUP=$3
CLIENTS=$4

# Check input parameters
if [[ $2 == "webserver" && $# -ne 2 ]] || [[ $2 == "appserver" && $# -ne 4 ]]; then echo $0: usage: AWS_Launch ENV webserver or AWS_Launch ENV appserver ASGGROUP CLIENTS; exit 1; fi
if [[ $1 != "uat" && $1 != "prod" ]]; then echo "Valid values for ENV are uat or prod"; exit 1; fi
if [[ $2 != "appserver" && $2 != "webserver" ]]; then echo "Valid values for ROLE are appserver or webserver"; exit 1; fi
if [[ $2 == "appserver" ]]; then 
   if [[ $3 != $ENV'appASG'[1-9] ]]; then echo "ASGGROUP invalid value, use: <env>appASG<1-9>"; exit 1; fi
fi

# Pull latest user-data.sh file from s3
aws s3 cp s3://CLIENT-scripts/common-env/user-data.sh .
if [[ $? -ne 0 ]]; then echo "AWS S3 user-data File Copy Command FAILURE"; exit 1; fi

echo -e "AWS_Launch STARTED FOR ENV=$ENV, ROLE=$ROLE, ASGGROUP=$ASGGROUP, CLIENTS=$CLIENTS ON $(date +"%Y-%m-%d-%H:%M:%S")"

# --- START WEB SERVER ---
if [[ $ROLE == "webserver" ]]; then

if [[ $ENV == "prod" ]]; then

# PROD assignments

# Assign Web Launch Config Variables
AMI="ami-...."
LCGNM="prodwebLaunchConfig"
KEYNM="CLIENT-web-keypair"
INSTTP="m3.medium"
USRDATA="file://user-data.sh"
SECGRP="sg-..."
INSTPROFILE="S3ReadAccessRole"

# Assign Web AutoScale Variables
ASNM="prodwebASG"
SUBNET="subnet-..."
INSTNM="prodweb"

# Assign Web Network Interface
NINM="prodwebNI"
NISECGRP="prodsgweb"

# Assign EIP for Webserver
EIP="eipalloc-..."

else

# UAT assignments

# Assign Web Launch Config Variables
AMI="ami-..."
LCGNM="uatwebLaunchConfig"
KEYNM="CLIENT-web-keypair"
INSTTP="m3.medium"
USRDATA="file://user-data.sh"
SECGRP="sg-..."
INSTPROFILE="S3ReadAccessRole"

# Assign Web AutoScale Variables
ASNM="uatwebASG"
SUBNET="subnet-..."
INSTNM="uatweb"

# Assign Web Network Interface
NINM="uatwebNI"
NISECGRP="uatsgweb"

# Assign EIP for Webserver
EIP="eipalloc-..."

# END uat or prod
fi

# If webserver already running under Apache Security Group, exit.
OLDWEB=`aws ec2 describe-network-interfaces --filters Name=group-name,Values="$NISECGRP" | grep NetworkInterfaceId | awk '{print $2}' | cut -d',' -f1`
if [[ ${#OLDWEB} > 0 ]]; then echo "Webserver Running. Terminate through autoscale"; exit 1; fi

# Tag AMI 		
aws ec2 create-tags --resources $AMI --tags Key=ENV,Value=$ENV Key=ROLE,Value=$ROLE
if [[ $? -ne 0 ]]; then echo "AWS create-tags for webserver AMI Command FAILURE"; exit 1; fi

# Create Launch Config
aws autoscaling create-launch-configuration --launch-configuration-name $LCGNM --key-name $KEYNM --image-id $AMI --instance-type $INSTTP --user-data $USRDATA --security-groups $SECGRP --instance-monitoring Enabled=false --block-device-mappings "[{\"DeviceName\": \"/dev/sda1\",\"Ebs\":{\"VolumeSize\":10}}]" --iam-instance-profile $INSTPROFILE --associate-public-ip-address 
if [[ $? -ne 0 ]]; then aws ec2 delete-tags --resources $AMI --tags Key=ENV Key=ROLE; echo "AWS create-launch-configuration webserver Command FAILURE"; exit 1; fi 

# Untag AMI 		
aws ec2 delete-tags --resources $AMI --tags Key=ENV Key=ROLE
if [[ $? -ne 0 ]]; then echo "AWS delete-tags for webserver AMI Command FAILURE"; exit 1; fi

sleep 5s

# AutoScaling	
aws autoscaling create-auto-scaling-group --auto-scaling-group-name $ASNM --launch-configuration-name $LCGNM --min-size 1 --max-size 1 --vpc-zone-identifier $SUBNET --health-check-grace-period 60 --tags Key=Name,Value=$INSTNM Key=ENV,Value=$ENV Key=ROLE,Value=$ROLE
if [[ $? -ne 0 ]]; then echo "AWS create-auto-scaling-group Command FAILURE"; exit 1; fi

sleep 30s

# END webserver
fi
# --- END WEB SERVER ---


# --- START APP SERVER ---
if [[ $ROLE == "appserver" ]]; then

if [[ $ENV == "prod" ]]; then

# PROD assignments

# Assign App Launch Config Variables
AMI="ami-..."
LCGNM="prodappLaunchConfig"
KEYNM="CLIENT-app-keypair"
INSTTP="m3.medium"
USRDATA="file://user-data.sh"
SECGRP="sg-..."
INSTPROFILE="S3ReadAccessRole"

# Assign AutoScale Variables
ASNM=$ASGGROUP
SUBNET="subnet-..."
INSTNM="prodapp"`echo -n $ASGGROUP | tail -c 1`

# Assign Network Interface
NINM="prodappNI"
NISECGRP="prodsgapp"

else

# UAT assignments

# Assign App Launch Config Variables
AMI="ami-..."
LCGNM="uatappLaunchConfig"
KEYNM="CLIENT-app-keypair"
INSTTP="m3.medium"
USRDATA="file://user-data.sh"
SECGRP="sg-..."
INSTPROFILE="S3ReadAccessRole"

# Assign AutoScale Variables
ASNM=$ASGGROUP
SUBNET="subnet-..."
INSTNM="uatapp"`echo -n $ASGGROUP | tail -c 1`

# Assign Network Interface
NINM="uatappNI"
NISECGRP="uatsgapp"

# END uat or prod
fi

# Tag AMI 		
aws ec2 create-tags --resources $AMI --tags Key=ENV,Value=$ENV Key=ROLE,Value=$ROLE Key=ASGGROUP,Value=$ASGGROUP Key=CLIENTS,Value=$CLIENTS
if [[ $? -ne 0 ]]; then echo "AWS create-tags for appserver AMI Command FAILURE"; exit 1; fi

# Create Launch Config if it does not exist 
app_asg_var=`aws ec2 describe-instances --filters "Name=tag:ROLE,Values=appserver" "Name=instance-state-name,Values=running" "Name=subnet-id,Values=$SUBNET"|grep ASGGROUP`
if [[ $app_asg_var == "" ]]; then
aws autoscaling create-launch-configuration --launch-configuration-name $LCGNM --key-name $KEYNM --image-id $AMI --instance-type $INSTTP --user-data $USRDATA --security-groups $SECGRP --instance-monitoring Enabled=false --block-device-mappings "[{\"DeviceName\": \"/dev/sda1\",\"Ebs\":{\"VolumeSize\":10,\"DeleteOnTermination\":false}}]" --iam-instance-profile $INSTPROFILE --associate-public-ip-address 
if [[ $? -ne 0 ]]; then aws ec2 delete-tags --resources $AMI --tags Key=ENV Key=ROLE Key=ASGGROUP Key=CLIENTS; echo "AWS create-launch-configuration appserver Command FAILURE"; exit 1; fi 
fi

# Untag AMI 		
aws ec2 delete-tags --resources $AMI --tags Key=ENV Key=ROLE Key=ASGGROUP Key=CLIENTS
if [[ $? -ne 0 ]]; then echo "AWS delete-tags for appserver AMI Command FAILURE"; exit 1; fi

sleep 5s

# AutoScaling	
aws autoscaling create-auto-scaling-group --auto-scaling-group-name $ASNM --launch-configuration-name $LCGNM --min-size 1 --max-size 1 --vpc-zone-identifier $SUBNET --health-check-grace-period 60 --tags Key=Name,Value=$INSTNM Key=ENV,Value=$ENV Key=ROLE,Value=$ROLE Key=ASGGROUP,Value=$ASGGROUP Key=CLIENTS,Value=$CLIENTS
if [[ $? -ne 0 ]]; then echo "AWS create-auto-scaling-group Command FAILURE"; exit 1; fi

sleep 45s

# Get VolumeId for instance
VOLID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$INSTNM" | grep VolumeId | awk -F\" '{print $4}')
if [[ $? -ne 0 ]]; then echo "AWS describe-instance EBS VOL Command FAILURE"; exit 1; fi

$ Tag Volume
aws ec2 create-tags --resources $VOLID --tags Key=Name,Value=$INSTNM
if [[ $? -ne 0 ]]; then echo "AWS create-tags EBS VOL Command FAILURE"; exit 1; fi

# END appserver
fi
# --- END APP SERVER ---


# --- START COMMON ---

# Get Network Interface from Environment
NTWINT=`aws ec2 describe-network-interfaces --filters Name=group-name,Values="$NISECGRP" | grep NetworkInterfaceId | awk '{print $2}' | cut -d',' -f1 | sed 's/"//g'`
if [[ $? -ne 0 ]]; then echo "AWS describe-network-interfaces Command FAILURE"; exit 1; fi

# Name Network Interface 
aws ec2 create-tags --resources $NTWINT --tags Key=Name,Value=$NINM
if [[ $? -ne 0 ]]; then echo "AWS create-tags for Network Interface Command FAILURE"; exit 1; fi

# --- END COMMON ---

# --- START WEB SERVER ---
if [[ $ROLE == "webserver" ]]; then

sleep 15s

# Associate EIP	
aws ec2 associate-address --allocation-id $EIP --network-interface-id $NTWINT
if [[ $? -ne 0 ]]; then echo "AWS Associate EIP Command FAILURE"; exit 1; fi

fi 
# --- END WEB SERVER ---

# Exit
echo -e "AWS_Launch SUCCESSFUL COMPLETION $(date +"%Y-%m-%d-%H:%M:%S")"
exit 0
