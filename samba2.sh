#!/bin/bash

############################################################################
#title          :samba2 SCRIPT
#description    :Thir SCRIPT will prepair samba4 domain controller
#author         :Gladson Carneiro Ramos
#date           :2023-02-20
#version        :2.0
#usage          :bash samba2.sh
############################################################################


key(){
    echo "Press any key to continue"
    read -n 1 -s -r
}

check_errors() {
	if [ $? -ne 0 ]
	then
		echo "[FAIL] - $ACTION"
		exit
	else
		echo "[OK] - $ACTION"
	fi
}

AD_DC_IP=`ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d / -f 1`
IFS='.' read -r -a ADDR <<< "$IP"
REVERSE_ZONE=`echo "${ADDR[2]}"."${ADDR[1]}"."${ADDR[0]}"`
echo "Type your realm please (lowercase)"
read REALM
echo "Creating reverse zone"
samba-tool dns zonecreate $AD_DC_IP $REVERSE_ZONE.in.addr.arpa -U Administrator

ACTION="LDAP test"
dig -t srv _ldap.tcp.$REALM > /dev/null 2>&1
check_errors

ACTION="Kerberos test"
dig -t srv _kerberos.tcp.$REALM > /dev/null 2>&1
check_errors

echo "Finished, rebooting"
key

systemctl reboot
