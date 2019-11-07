#Quick Linux Note on SCP before that 
scp -r root@172.29.99.238:/<datastore>/<sourceIP/hostname>/ root@172.29.99.235:/vmfs/volumes/<destinationdatastore>


#Notes from linux stuff

iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 443 -j DNAT --to-destination <dest ip add>
change in vi/etc/sysctl,conf
#controls ip packet forward
net.ipv4.ip_forward


This tests whether the script has been invoked with the correct number of parameters

__

E_WRONG_ARGS=85
script_parameters="-a -h -m -z"
#                  -a = all, -h = help, etc.

if [ $# -ne $Number_of_expected_args ]
then
  echo "Usage: `basename $0` $script_parameters"
  # `basename $0` is the script's filename.
  exit $E_WRONG_ARGS
fi




__



ls /home /ham 2>&1

command on that for that file, 2 is the standard err out
2 > redirect 2
&1 is the location - send to same place as 1

set -o noclobber

| after redireciton overrides the safety
< reads from file
df -h <
makes it the body of the text then


___________

iptables -vnL
works as iptables -L-v -n
-v means some debug
-vv most is debug whats happening
-vvv some cases LITERALLY all thats happening like with SSH

