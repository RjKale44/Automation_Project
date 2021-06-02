#!/bin/bash

#Update the logs to S3 bucket
upload_to_s3()
{
tar -zcvf /tmp/$myname-httpd-logs-$timestamp.tar /var/log/apache2/*.log
aws s3 cp /tmp/$myname-httpd-logs-$timestamp.tar s3://$s3_bucket/$myname-httpd-logs-$timestamp.tar
}

#Update packages
sudo apt update -y > apt_update_$(date +"%Y_%m_%d_%I_%M_%p").log
serv=apache2
servstat1='(dead)'
servstat2='(running)'
myname=aniruddha
s3_bucket=upgrad-aniruddha
timestamp=$(date '+%d%m%Y-%H%M%S')

#Check if apache installed or not and install if not available
apache=$(dpkg --get-selections | grep apache | awk '{print $1}' | head -1)
if [[ $apache == "apache2" ]]; 
then
       echo "apache is installed"
else
	echo "apache not installed"	
	sudo apt install apache2
fi

#Check status of service and enable id not running

service $serv status | grep -i 'running\|inactive\|dead\|stopped' | awk '{print $3}' | while read output;
do
echo $output
if [ "$output" == "$servstat1" ]; then
	service $serv start
    	echo "$serv service is UP now.!" 
elif [ "$output" == "$servstat2" ]; then
	echo "$serv is running"	
	upload_to_s3
fi
done
