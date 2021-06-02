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
        echo
else
	echo "$serv not installed , Installing apache2"	
	sudo apt install $serv -y
fi

#Check status of service and enable id not running
service $serv status | grep -i 'running\|inactive\|dead\|stopped' | awk '{print $3}' | while read output;
do
echo $output
if [ "$output" == "$servstat1" ]; then
	service $serv start
    	echo "$serv service is UP now.!" 
elif [ "$output" == "$servstat2" ]; then
	echo "$serv is running and logs are uploaded to S3 bucket $s3_bucket"	
	upload_to_s3
fi
done
size=$(du -s -h /tmp/$myname-httpd-logs-$timestamp.tar | awk '{print $1}')
FILE=/var/www/html/inventory.html
if test -f "$FILE"; then
        echo "$FILE exists."
        sed -i "`wc -l < /var/www/html/inventory.html`i\\<p>httpd-logs&emsp;$timestamp&emsp;logs&emsp;$size</p>\\" /var/www/html/inventory.html
else
        echo "<!DOCTYPE html>" > $FILE
        echo "<html><body><h1>Inventory File</h1>" >> $FILE
        echo "<p>Log Type  &emsp;Date Created   &emsp;Type&emsp;Size</p>" >> $FILE
        echo "<p>httpd-logs&emsp;$timestamp&emsp;logs&emsp;$size</p>" >> $FILE 
        echo "</body></html>" >> $FILE
        echo "$FILE created"
fi



#add cron to instance if not present
cronlist=/etc/cron.d/automation
if test -f "$cronlist"; then # | grep -q "/root/Automation_Project/automation.sh"; then
	echo "Cron present"
else
	echo "* * * * * /root/Automation_Project/automation.sh" > /etc/cron.d/automation
fi
