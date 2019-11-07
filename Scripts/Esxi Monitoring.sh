#!/bin/sh
#Original Author: Nickolaus Vendel
#This script monitors the CPU, RAM and Disk space usage on an esxi host
#This script should be scheduled to run every 5 minutes in cron
#The MonitoringESXiStartup.sh handles the configurations needed for this to work

#Updates made by Matthew Fitzgerald - Added section to ensure esxtop pulls usable data
#changed the search parameter within CSV for CPU and RAM values.  CPU and RAM values are now
#averaged over a period of 15 minutes for a more accurate report.

#Updates made by Nickolaus Vendel
#removed datastore monitoring, added event counting

###################
#Variables setting#
###################

#These values are the % thresholds
#Ensure the TOTAL_RAM value has been updated by the MonitoringESXiStartup.sh script
MAX_CPU=90
MAX_RAM=90
TOTAL_RAM= #<ram of device number of GB's>
EVENT_COUNT=3

#Due to collecting Free RAM due to ESXi limitations configures value to compare against for log check
THRESHOLD_PERCENT_RAM=$((TOTAL_RAM * (${MAX_RAM})/100))

#########################################
#Backup existing log from esxcli command#
#########################################

#Backs up the current log set not including the message that says you cleared the log
HARDWARE_EVENTS=$(esxcli hardware ipmi sel list)
echo $HARDWARE_EVENTS |grep -v "Message: Assert + Event Logging Disabled Log area reset/cleared" >> /scratch/log/HARDWARE_EVENTS.log

############################
#Gathering Host Information#
############################

#gathers the output for CPU and RAM into a csv file.  This has a control to ensure that esxtop pulls valid information
esxtop -b -n 1 > /scratch/log/esxihostmonitoring.csv

#grabs CPU and RAM usage
CPU_LINE=$(awk -F, '{ for(i=1;i<=NF;i++){if( $i ~ /Physical Cpu\(\_Total\)\\\% Util Time/) print i} }' /scratch/log/esxihostmonitoring.csv)
RAM_LINE=$(awk -F, '{ for(i=1;i<=NF;i++){if( $i ~ /Memory\\\Free MBytes/) print i} }' /scratch/log/esxihostmonitoring.csv)
CPU_UTIL=$(awk -F, '{print $'$CPU_LINE'}' /scratch/log/esxihostmonitoring.csv)
FREE_ESXI_RAM=$(awk -F, '{print $'$RAM_LINE'}' /scratch/log/esxihostmonitoring.csv)

#Grabs powersupply and hard drive information needed
POWER_SUPPLY_STATUS=$(esxcli hardware ipmi sel list | grep "Redundancy Lost" | grep Message)
DRIVE_STATUS=$(esxcli hardware ipmi sel list | grep "Drive Fault" | grep Message)

#########################
#Converting and Rounding#
#########################

#Converts CPU usage to a value usable by the script
ESXI_CPU_UTIL=$(echo "$CPU_UTIL" | grep -v Cpu | cut -d '"' -f 2)

#Convert the amount of ESXI_RAM to GB values
ESXI_RAM=$(echo "$FREE_ESXI_RAM" | grep -v Free | cut -d '"' -f 2 | awk '{print $1/1024}')

#Rounds the values from the data as UNIX has difficulty with floating point values
ROUNDED_THRESHOLD_RAM=$(echo "$THRESHOLD_PERCENT_RAM" | awk '{printf("%d\n",$1 + 0.5)}')
ROUNDED_CPU=$(echo "$ESXI_CPU_UTIL" | awk '{printf("%d\n",$1 + 0.5)}')
ROUNDED_RAM=$(echo "$ESXI_RAM" | awk '{printf("%d\n",$1 + 0.5)}')

#Calculate the USED_RAM based on the TOTAL_RAM minus the FREE_RAM
USED_RAM=`expr $TOTAL_RAM - $ROUNDED_RAM`

################################
#Logic Check for Event counting#
################################

#On these counters - would need to figure out a way to update the text file to make sure blank lines
#intead of having to delete and remake for the 0 line aspect otherwise itll start once first event is thrown at 2

#CPU counter check
if [ "$ROUNDED_CPU" -ge  "$MAX_CPU" ]
	then
		echo "Threshold hit" >> /scratch/log/cpueventcheck.txt
		CPU_COUNTER=$(cat /scratch/log/cpueventcheck.txt | wc -l)
	else
		echo $null > /scratch/log/cpueventcheck.txt
		CPU_COUNTER=0
fi

if [ "$CPU_COUNTER" -ge "$EVENT_COUNT" ]
then
	#This allows it to read as "not empty"
	CPU_EVENT=1
fi

#RAM Counter check
if [ "$USED_RAM" -ge "$ROUNDED_THRESHOLD_RAM" ]
	then
		echo "Threshold hit" >> /scratch/log/rameventcheck.txt
		RAM_COUNTER=$(cat /scratch/log/rameventcheck.txt | wc -l)
	else
		echo $null > /scratch/log/rameventcheck.txt
		RAM_COUNTER=0
fi

if [ "$RAM_COUNTER" -ge "$EVENT_COUNT" ]
then
	#This allows it to read as "not empty"
	RAM_EVENT=1
fi

########################################
#Logs errors and sends to syslog server#
########################################

LOGDATE=$(date)
#CPU check
if [ -n "$CPU_EVENT" ]
then
	logger -p user.crit -t ESXiCPU CPU UTIL percent used is higher than "$MAX_CPU "
	echo "$LOGDATE [CPU] CPU percent used higher than $MAX_CPU" >> /scratch/log/esxi.log
	echo $null > /scratch/log/cpueventcheck.txt
fi

#RAM check
if [ -n "$RAM_EVENT" ]
then
	logger -p user.crit -t ESXiMEM Memory percent used is higher than "$MAX_RAM"
	echo "$LOGDATE [MEM] - Memory percent used is higher than $MAX_RAM" >> /scratch/log/esxi.log
	echo $null > /scratch/log/cpueventcheck.txt
fi

#Reads if the variables are empty if they aren't empty then it throws the message
#Power Supply Events
if [ -n "$POWER_SUPPLY_STATUS" ]
then
	logger -p user.crit -t ESXiPSU There is a problem with a Power Supply, check redundancy status
	echo "$LOGDATE [PSU] - There is a problem with a Power Supply, check redundancy status" >> /scratch/log/esxi.log
fi

#Hard Drive Events
if [ -n "$DRIVE_STATUS" ]
then
  logger -p user.crit -t ESXiDRIVE There is a problem with a Hard Drive, check drive status for failure
	echo "$LOGDATE [HDD] - There is a problem with a hard drive, check drive status for failure" >> /scratch/log/esxi.log
fi

#################
#Log Maintenance#
#################

#Clears log in place for rerun parsing
esxcli hardware ipmi sel clear

exit