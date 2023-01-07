#!/bin/bash

line(){
    echo "-------------------------------------------------------------------------------------"
}

key(){
    echo "Press any key to continue"
    read -n 1 -s -r
}
install(){
    echo "Installing samba..."
    sleep 1
    echo "Fill up nex window your realm ALL CAPS [MY.LOCAL.DOMAIN]"
    sleep 2
    echo "Next fill kerberos servers, normal letter [ad1.mylocal.domain ad2.my.local.domain]"
    sleep 2
    echo "After, kerberos adm, normal as well [ad1.my.local.domain]."
    sleep 2
    key

    line


    sudo apt-get install acl attr autoconf bind9utils bison build-essential \
    debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user \
    libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev \
    libcap-dev libcups2-dev libgnutls28-dev libgpgme-dev libjson-perl libldap2-dev \
    libncurses5-dev libpam0g-dev libparse-yapp-perl libpopt-dev libreadline-dev \
    nettle-dev perl perl-modules-5.30 pkg-config  python-all-dev python-crypto python2-dbg \
    python-dev-is-python2 python-dnspython python3-dnspython python2-gpg python3-gpg \
    python-markdown python3-markdown python3-dev xsltproc zlib1g-dev liblmdb-dev \
    lmdb-utils acl attr samba samba-dsdb-modules samba-vfs-modules winbind krb5-config \
    krb5-user dnsutils
    
    line
    echo "Preparing the installation"
    sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
    sleep 1
    line
    echo "Fill up realm ALL CAPS"
    sleep 1
    key
    sudo samba-tool domain provision --use-rfc2307 --interactive
    echo "Finish, rebooting"
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
