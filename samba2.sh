
key(){
    echo "Press any key to continue"
    read -n 1 -s -r
}

check_errors() {
	if [ $? -ne 0 ] ; then
		echo "[FAIL] - $ACTION"
		exit
	else
		echo "[OK] - $ACTION"
	fi
}
    
    
 #   echo "Testing smbclient" 
 #   smbclient -L localhost -U Administrator

 #   echo "Netlogon ls"
 #   smbclient //localhost/netlogon -UAdministrator -c 'ls'
#ACTION="Samba unmask"
#systemctl unmask samba-ad-dc > /dev/null 2>&1
#check_errors

#ACTION="Samba enable"
#systemctl enable samba-ad-dc > /dev/null 2>&1
#check_errors

#ACTION="Samba restart"
#systemctl restart samba-ad-dc > /dev/null 2>&1
#check_errors

AD_DC_IP=`ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d / -f 1`
IFS='.' read -r -a ADDR <<< "$IP"
REVERSE_ZONE=`echo "${ADDR[2]}"."${ADDR[1]}"."${ADDR[0]}"`
echo "Type your realm please"
read REALM
echo "Creating reverse zone"
samba-tool dns zonecreate $AD_DC_IP $REVERSE_ZONE.in.addr.arpa -U Administrator

ACTION="LDAP test"
dig -t srv _ldap.tcp.$REALM > /dev/null 2>&1
check_errors

ACTION="Kerberos test"
dig -t srv _kerberos.tcp.$REALM > /dev/null 2>&1
check_errors

#echo "Kinit test"
#kinit Administrator

echo "Finished, rebooting"
key

reboot
