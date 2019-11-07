#! /bin/sh
#Author: Nickolaus Vendel with contrubtions by Censored Coworker name
#This script is to be run to allow the esxi host set up to be configured with the settings required for deployment

########################################################################
#REQUIREMENTS FOR RUNNING SCRIPT                                       #
#ESXiMonitoring.sh installed to /vmfs/volumes/<datastore1>             #
#If installing OMSA:                                                   #
#Internet Connectivity to Dell or                                      #
#OMSA ZIP file installed to /vmfs/volumes/<datastore1>/OMSA            #
########################################################################

#Variables for set up
SYSLOG_SERVER=""
SYSLOG_SERVER_LISTEN_PORT=514
MONITOR_SCRIPT_NAME=ESXiMonitoring.sh
DATASTORE1=$(ls /vmfs/volumes | egrep -i "ds|datastore" | head -1)
DATASTORE2=$(ls /vmfs/volumes | egrep -i "ds|datastore" | tail -1)
MONITOR_SCRIPT_PATH=/vmfs/volumes/$DATASTORE1/$MONITOR_SCRIPT_NAME
TOTAL_RAM=$(smbiosDump | grep -A 12 'Memory Device' | grep Size: | grep -v No | awk '{ print $2 }' | awk '{ SUM += $1 } END { print SUM }')

#Set permission to monitoring script
chmod 750 $MONITOR_SCRIPT_PATH

#Gathers syslog server IP information
while [ -z "$SYSLOG_SERVER" ]
do
	read -p "Please input the IP address of the SOS syslog server, type 'stop' to quit  : " SYSLOG_SERVER
	if [ $SYSLOG_SERVER = "stop" ]
	then
		/bin/echo "SOS monitoring setup has been ABORTED"
		exit 1;
	fi
done

#Writes RAM and DATASTORE variables into ESXiMonitoring.sh
sed -i "s/ #<ram\ of\ device\ number\ of\ GB's>/$TOTAL_RAM/g" /vmfs/volumes/$DATASTORE1/ESXiMonitoring.sh
sed -i "s/ #<datastore1>/$DATASTORE1/" /vmfs/volumes/$DATASTORE1/ESXiMonitoring.sh
sed -i "s/ #<datastore2>/$DATASTORE2/" /vmfs/volumes/$DATASTORE1/ESXiMonitoring.sh

#Schedules Cron Job
/bin/kill $(cat /var/run/crond.pid)
/bin/echo "*/5  *    *   *   *   $MONITOR_SCRIPT_PATH" >> /var/spool/cron/crontabs/root
/bin/crond

LOCALSH_VRIBS_CONFIG=$(grep "^crond$" /etc/rc.local.d/local.sh)
LOCALSH_STANDARD_CONFIG=$(grep "exit 0" /etc/rc.local.d/local.sh)

#Configures Cron Job persistence - additional accounting for if VRIBS is installed
if [ "$LOCALSH_VRIBS_CONFIG" ]
	then
		sed -i "/^crond$/i\/bin/echo '*/5  *    *   *   *   $MONITOR_SCRIPT_PATH' >> /var/spool/cron/crontabs/root" /etc/rc.local.d/local.sh
		/sbin/auto-backup.sh
elif [ "$LOCALSH_STANDARD_CONFIG" ]
	then
		sed -i '/exit/i\/bin/kill $(cat /var/run/crond.pid)' /etc/rc.local.d/local.sh
		sed -i "/exit/i\/bin/echo '*/5  *    *   *   *   $MONITOR_SCRIPT_PATH' >> /var/spool/cron/crontabs/root" /etc/rc.local.d/local.sh
		sed -i '/exit/i\crond' /etc/rc.local.d/local.sh
		/sbin/auto-backup.sh
else
	/bin/echo "The '/etc/rc.local.d/local.sh' file was not updated. Please investigate. Aborting script."
	exit -1
fi

#Configure Syslog server settings
esxcli system syslog config set --logdir=/scratch/log --loghost=${SYSLOG_SERVER}:${SYSLOG_SERVER_LISTEN_PORT} --logdir-unique=true
esxcli system syslog reload

#Configures syslog firewall ruleset
esxcli network firewall ruleset set --ruleset-id=syslog --enabled=true
esxcli network firewall refresh

#Checks for OMSA if not installed gives options to install, if staged installs, if installed returns that it has been installed already
OMSACHECK=$(esxcli software vib get |grep OpenManage)
#Check if Directory exists
if [ -d /vmfs/volumes/$DATASTORE1/OMSA ]
	then DIRCHECK="Path exists"
fi

if [ "$OMSACHECK" ]
	then
		/bin/echo "OMSA is already installed, continuing script."
	elif [ "$DIRCHECK" ]
		then
			esxcli software vib install -d /vmfs/volumes/$DATASTORE1/OMSA/*.zip
		else
			read -p "If you have internet connectivity to Dell's website would you like to install OMSA? WARNING: REQUIRES REBOOT y/n : " OMSACHOICE
			case $OMSACHOICE in
				y|Y|Yes|yes)
					mkdir /vmfs/volumes/$DATASTORE1/OMSA
					wget "http://downloads.dell.com/FOLDER04616279M/1/OM-SrvAdmin-Dell-Web-9.1.0-2757.VIB-ESX65i_A00.zip" -P /vmfs/volumes/$DATASTORE1/OMSA/
					esxcli software vib install -d /vmfs/volumes/$DATASTORE1/OMSA/*.zip;;
				n|N|No|no)
					exit;;
				esac
fi

exit
