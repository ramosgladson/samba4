
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

    echo "Type your ip please"
    read AD_DC_IP
    echo "Type reverse zone please (e.g ip=192.168.0.99 reverse_zone=0.168.192) "
    read REVERSE_ZONE
    echo "Type your realm please"
    read REALM
    echo "Creating reverse zone"
    samba-tool dns zonecreate $AD_DC_IP $REVERSE_ZONE.in.addr.arpa -U Administrator
    echo "Testing smbclient" 
    smbclient -L localhost -U Administrator

    echo "Netlogon ls"
    smbclient //localhost/netlogon -UAdministrator -c 'ls'

    ACTION="LDAP test"
    dig -t srv _ldap.tcp.$REALM > /dev/null 2>&1
    check_errors

    ACTION="Kerberos test"
    dig -t srv _kerberos.tcp.$REALM > /dev/null 2>&1
    check_errors

    echo "Kinit test"
    kinit Administrator

    echo "Finished, rebooting"
    key

    sudo reboot
