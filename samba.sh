#!/bin/bash

############################################################################
#title           :samba4-script
#description     :This script will prepair samba4 domain controller
#author		 :Gladson Carneiro Ramos
#date            :2023-01-08
#version         :0.2
#usage		 :bash samba4.sh
############################################################################

line(){
    echo "-------------------------------------------------------------------------------------"
}

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



install(){
    echo "Installing samba..."
    echo "Fill up nex window your realm ALL CAPS [MY.LOCAL.DOMAIN]"
    echo "Next fill kerberos servers, normal letter [ad1.mylocal.domain ad2.my.local.domain]"
    echo "After, kerberos adm, normal as well [ad1.my.local.domain]."
    key

    line

    ACTION="Installing packages"
    sudo apt-get install acl attr autoconf bind9utils bison build-essential \
    debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user \
    libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev \
    libcap-dev libcups2-dev libgnutls28-dev libgpgme-dev libjson-perl \
    libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl \
    libpopt-dev libreadline-dev nettle-dev perl perl-modules-5.30 pkg-config \
    python-all-dev python-crypto python2-dbg python-dev-is-python2 python-dnspython \
    python3-dnspython python3-gpg python-markdown python3-markdown \
    python3-dev xsltproc zlib1g-dev liblmdb-dev lmdb-utils acl attr \
    samba samba-dsdb-modules samba-vfs-modules winbind krb5-config \
    krb5-user dnsutils smbclient -y > /dev/null 2>&1
    check_errors

    line

    ACTION="Preparing the installation"
    sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp > /dev/null 2>&1
    check_errors

    sleep 1
    
    echo "Fill up realm ALL CAPS"
    key
    
    ACTION="Setting domain controller"
    sudo samba-tool domain provision --use-rfc2307 --interactive > /dev/null 2>&1
    check_errors

    ACTION="Samba unmask"
    sudo systemctl unmask samba-ad-dc > /dev/null 2>&1
    check_errors
    

    ACTION="Samba unmask"
    sudo systemctl enable samba-ad-dc > /dev/null 2>&1
    check_errors
    
    
    ACTION="Samba unmask"
    sudo systemctl restart samba-ad-dc > /dev/null 2>&1
    check_errors
    
    echo "Type your ip please"
    read AD_DC_IP
    echo "Type reverse zone please (e.g ip=192.168.0.99 reverse_zone=0.168.192) "
    read REVERSE_ZONE
    echo "Type your realm please"
    read REALM

    ACTION="Reverse zone"
    samba-tool dns zonecreate $AD_DC_IP $REVERSE_ZONE.in.addr.arpa -U Administrator > /dev/null 2>&1
    check_errors
    
    ACTION="Smbclient test"
    smbclient -L localhost -U Administrator > /dev/null 2>&1
    check_errors

    ACTION="Netlogon ls"
    smbclient //localhost/netlogon -UAdministrator -c 'ls' > /dev/null 2>&1
    check_errors

    ACTION="LDAP test"
    dig -t srv _ldap.tcp.$REALM > /dev/null 2>&1
    check_errors

    ACTION="Kerberos test"
    dig -t srv _kerberos.tcp.$REALM > /dev/null 2>&1
    check_errors

    ACTION="Kinit test"
    kinit Administrator > /dev/null 2>&1
    check_errors

    echo "Finished, rebooting"
    key

    sudo reboot
}


if [ $(lsb_release -sr) == "20.04" ];
then
    install
else
    echo "This script was made to run on linux ubuntu 20.04 and your version is: "
    echo "$(lsb_release -sd)"
    echo "Proced any way? [y/N]"
    read answer
    if [ $answer == "y" ];
    then
        install
    else
        echo "ok, bye"
    fi
fi
