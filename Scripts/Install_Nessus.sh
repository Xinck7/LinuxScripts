#!/bin/bash

#Setup Variables
Rhel_based_OS_ver="$(rpm -E %{rhel})"
Debian_based_OS_ver="$(grep -i version_id /etc/os-release)"
Wget_URL_Base="<base_URL_for_MSI>"
Whirlpool_cert="/path/to/cert.pem"
Whirlpool_cert_URL="<somthing>.pem"
Whirlpool_key="longstringkey"
Whirlpool_host="hostname"
Whirlpool_port="port"
whirlpool_group="group"

#Set RPM Versions based on OS
if [ "$Rhel_based_OS_ver" == 6 ]
then 
    RPM_version="NessusAgent-<version>.rpm"
elif [ "$Rhel_based_OS_ver" == 7 ]
then
    RPM_version="NessusAgent-<version>.rpm"
elif  echo "$Debian_based_OS_ver" | grep 14 -q
then
    RPM_version="NessusAgent-<version>.deb"
elif  echo "$Debian_based_OS_ver" | grep 18 -q
then
    RPM_version="NessusAgent-<version>.deb"
else
    sleep 0
    echo 'hit else statement need to troubleshoot'
fi

#Download certificate
cd /root
wget $Wget_URL_Base$Whirlpool_cert_URL

#Collect RPM
cd /opt
wget $Wget_URL_Base$RPM_version

#Install RPM based on OS
if [ "$Rhel_based_OS_ver" == 6 ]
then 
    rpm -ivh /opt/$RPM_version
elif [ "$Rhel_based_OS_ver" == 7 ]
then
    rpm -ivh /opt/$RPM_version
elif  echo "$Debian_based_OS_ver" | grep 14 -q
then
    dpkg -i /opt/$RPM_version
elif  echo "$Debian_based_OS_ver" | grep 18 -q
then
    dpkg -i /opt/$RPM_version
else
    sleep 0
    echo 'hit else statement need to troubleshoot'
fi


#Link to whirlpool
/opt/nessus_agent/sbin/nessuscli agent link --ca-path=$Whirlpool_cert --key=$Whirlpool_key --host=$Whirlpool_host --port=$Whirlpool_port --groups=$whirlpool_group

#Start service
service nessusagent start

#Start service and set to auto-start if not done by default
if [ "$Rhel_based_OS_ver" == 6 ]
then 
    service nessusagent start
    chkconfig nessusagent on
elif [ "$Rhel_based_OS_ver" == 7 ]
then
    systemctl start nessusagent
    systemctl enable nessusagent
elif  echo "$Debian_based_OS_ver" | grep 18 -q
then
    systemctl start nessusagent
    systemctl enable nessusagent
fi
exit 0