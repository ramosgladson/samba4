#!/bin/bash

############################################################################
#title          :samba SCRIPT
#description    :Thir SCRIPT will prepair samba4 domain controller
#author         :Gladson Carneiro Ramos
#date           :2023-02-22
#version        :2.2
#usage          :bash samba.sh
############################################################################


netplan_conf(){
cat << EOF > `ls /etc/netplan/0*`
network:
  ethernets:
    ens18:
      addresses:
      - $IP/24
      gateway4: $GATEWAY
      nameservers:
        addresses:
        - $IP
        search:
        - $REALM
  version: 2
EOF
}

build_sh(){
cat << EOF > build.sh
#!/bin/bash
cd "\${0%/*}"

./configure --prefix /usr --enable-fhs --enable-cups --sysconfdir=/etc --localstatedir=/var \
--with-privatedir=/var/lib/samba/private --with-piddir=/var/run/samba --with-automount \
--datadir=/usr/share --with-lockdir=/var/run/samba --with-statedir=/var/lib/samba  \
--with-cachedir=/var/cache/samba --with-systemd

export PATH=$PATH:/usr/sbin/

make -j $(nproc)
make install
ldconfig
EOF
}

resolv(){
cat << EOF > /etc/resolv.conf
nameserver $IP
search $REALM

EOF
}


service(){
cat << EOF > /etc/systemd/system/samba-ad-dc.service
[Unit]
Description=Samba Active Directory Domain Controller
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/sbin/samba -D
PIDFile=/run/samba/samba.pid
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
}

prepare(){
    
    IP=`ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d / -f 1`
    INTERFACE=`ip -4 addr show scope global | grep -i broadcast | awk '{print $2}' | sed 's/://'`
    echo "What is your realm (lowercase)"
    read REALM
    case $DISTRO in
        ubuntu)
            echo "Type your network gateway"
            read GATEWAY
            netplan_conf
            netplan apply
            ;;
        debian)
            mv /etc/resolv.conf /etc/resolv.conf.bkp
            resolv          
            ;;
        centos)
            nmcli con mod $INTERFACE IPv4.method manual
            nmcli con mod $INTERFACE IPv4.dns $IP IPv4.dns-search $REALM
            nmcli con down $INTERFACE && nmcli con up $INTERFACE            
            ;;
        *)
            echo "configurar resolv.conf"
            ;;
    esac
    echo "$IP $NAME.$REALM $NAME" >> /etc/hosts
}


yes_or_no () {
    case $1 in
        [yY][eE][sS]|[yY])            
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}
line(){
    echo "-------------------------------------------------------------------------------------"
}

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

start(){
    echo "Would you like to install dependencies?"
    read ANSWER
    yes_or_no $ANSWER
    if [ "$?" = '1' ]
    then
        install_dependencies
    else
        echo "Are you sure?"
        read ANSWER
        yes_or_no $ANSWER
        if [ "$?" = '1' ]
        then
            echo "ok"
        else
            install_dependencies
        fi
    fi
}

install_dependencies(){
    if [ -e _dependencies/bootstrap_generated-dists_${DISTROVERSION}_bootstrap.sh ]
    then
        ./_dependencies/bootstrap_generated-dists_${DISTROVERSION}_bootstrap.sh
    else
        echo "There is no dependencies script for your distro/version (${DISTROVERSION})"
        echo "What would you like to do?"
        SCRIPTS=$(ls _dependencies | cut -d"_" -f3)  
        i=0
        for SCRIPT in $SCRIPTS  
        do  
            ((i++))
            echo $i "- Install" $SCRIPT "dependencies" 
        done
        echo $(ls -l _dependencies | awk '{print $9}' | cut -d"_" -f3 | wc -l) "- Inform dependencies / abort scritp" 
        echo -n "Option: "
        read OPT
        i=0
        valid=true
        for SCRIPT in $SCRIPTS  
        do  
            ((i++))
            if [ $OPT = $i ]
            then
                DISTROVERSION=$SCRIPT                
                install_dependencies
                valid=true
            else
                valid="false"
            fi
        done
        if [ valid = "false" ]
        then
            echo "Would you like to abort script?"
            echo "Yes to abort. No to install packages"
            read ANSWER
            yes_or_no $ANSWER
            if [ "$?" = '1' ]
            then
                exit
            fi
            echo "Please inform packages now:"
            read DEPENDENCIES
            case $DISTRO in 
                ubuntu)
                    apt update -y && apt upgrade -y
                    apt install $DEPENDENCIES
                    ;;
                debian)
                    apt update -y && apt upgrade -y
                    apt install $DEPENDENCIES
                    ;;
                centos)
                    yum update -y && yum upgrade -y
                    yum install $DEPENDENCIES
                    ;; 
                *)
                    echo "Type your distro install command please:"
                    read COMMANDO
                    $COMMANDO $DEPENDENCIES
                    ;;
            esac
        fi    
        
    fi                          
}

package_or_build(){
    echo -n "How would you like to install?
    1 - Build
    2 - Package 
    Option: "
    read OPT
    case $OPT in
        1)
            build
            ;;
        2)
            package
            ;;
        *)
            echo "Option not found"
            package_or_build
            ;;
    esac

}

build(){
    if [ $DISTRO = 'ubuntu' ]
    then
        apt install -y wget 2> /dev/null 
        case $VERSION in
            1804)
                wget https://download.samba.org/pub/samba/stable/samba-4.17.5.tar.gz
                ;;
            
            2004)
                wget https://download.samba.org/pub/samba/stable/samba-4.17.5.tar.gz
                ;;                    
            *)
                curl https://download.samba.org/pub/samba/stable/ | grep tar.gz | awk '{print $8}' | cut -d'"' -f2 | grep samba-4.1
                echo "Your distro/version has not samba version homologated, witch samba would you like to install (entire name please)?"
                read SAMBA
                wget https://download.samba.org/pub/samba/stable/$SAMBA
                ;;          
        esac

    elif [ $DISTRO = 'debian' ]
    then
        apt install -y wget curl 2> /dev/null
        case $VERSION in
            10)
                wget https://download.samba.org/pub/samba/stable/samba-4.15.13.tar.gz
                ;;
            
            11)
                wget https://download.samba.org/pub/samba/stable/samba-4.17.5.tar.gz
                ;;
            *)
                curl https://download.samba.org/pub/samba/stable/ | grep tar.gz | awk '{print $8}' | cut -d'"' -f2 | grep samba-4.1
                echo "Your distro/version has not samba version homologated, witch samba would you like to install (entire name please)?"
                read SAMBA
                wget https://download.samba.org/pub/samba/stable/${SAMBA}
                ;;
        esac

    elif [ $DISTRO = 'centos' ]
    then
        yum install -y wget curl 2> /dev/null
        case $VERSION in
            7)
                wget https://download.samba.org/pub/samba/stable/samba-4.15.13.tar.gz
                ;;
            
            8)
                wget https://download.samba.org/pub/samba/stable/samba-4.15.13.tar.gz
                ;;
            *)
                curl https://download.samba.org/pub/samba/stable/ | grep tar.gz | awk '{print $8}' | cut -d'"' -f2 | grep samba-4.1
                echo "Your distro/version has not samba version homologated, witch samba would you like to install (entire name please)?"
                read SAMBA
                wget https://download.samba.org/pub/samba/stable/${SAMBA}
                ;;
        esac        
    else
        apt install -y wget curl 2> /dev/null
        yum install -y wget curl 2> /dev/null
        zypper --non-interactive install wget 2> /dev/null
        echo "This is samba versions available:"
        curl https://download.samba.org/pub/samba/stable/ | grep tar.gz | awk '{print $8}' | cut -d'"' -f2 | grep samba-4.1
        echo "Your distro/version has not samba version homologated, witch samba would you like to install (entire name please)?"
        read SAMBA
        wget https://download.samba.org/pub/samba/stable/${SAMBA}
    fi

    tar xvzf samba-*.tar.gz
    DIR=`ls -l | grep d | awk '{print $9}' | grep ^samba`
    build_sh
    mv build.sh $DIR/
    chmod +x $DIR/build.sh
    ./$DIR/build.sh
    
    
    echo "Fill up realm (UPPERCASE)"   
    samba-tool domain provision --use-rfc2307 --interactive

    mv /etc/krb5.conf /etc/krb5.conf.bkp

    ACTION="Coping krb5.conf"
    cp /var/lib/samba/private/krb5.conf /etc/krb5.conf > /dev/null 2>&1
    check_errors

    service
    if [ $DISTRO = 'centos' ]
    then
        chcon -u system_u -r object_r -t bin_t /usr/sbin/samba* 
    fi

    ACTION="Daemon reload"
    systemctl daemon-reload > /dev/null 2>&1
    check_errors

    ACTION="Samba enable"
    systemctl enable samba-ad-dc > /dev/null 2>&1
    check_errors

    ACTION="Samba unmask"
    systemctl unmask samba-ad-dc > /dev/null 2>&1
    check_errors
       
}



package(){
    PACK="true"
    case $DISTRO in
        ubuntu)
            ACTION="Ubuntu package install"
            apt-get install -y acl attr samba samba-dsdb-modules samba-vfs-modules winbind libpam-winbind libnss-winbind krb5-config krb5-user dnsutils > /dev/null 2>&1
            check_errors
            ;;
        debian)
            ACTION="Debian package install"
            apt-get install -y acl attr samba samba-dsdb-modules samba-vfs-modules winbind libpam-winbind libnss-winbind krb5-config krb5-user dnsutils > /dev/null 2>&1
            check_errors
            ;;
        opensuse)
            ACTION="OpenSUSE package install"
            zypper install -y samba samba-winbind samba-ad-dc > /dev/null 2>&1
            check_errors
            ;;
        fedora)
            ACTION="Fedora/feeBSD package install"
            pkg install net/samba44 > /dev/null 2>&1
            check_errors
            ;;
        *)
            echo "Package for you distro not found" 
            echo "Red Hat does not provide packages for running Samba as an AD DC. As an alternative build samba-ad"      
            echo -n "Which distro package would you like to install?
            1 - Ubuntu
            2 - Debian
            3 - OpenSUSE
            4 - Fedora/freeBSD
            5 - Install no package, build instead
            6 - Exit
            Option: "
            read OPT
            case $OPT in
                1)
                    DISTRO="ubuntu"
                    ;;
                2)
                    DISTRO="debian"
                    ;;
                3)
                    DISTRO="opensuse"
                    ;;
                4)
                    DISTRO="fedora"
                    ;;
                5)
                    build
                    PACK="false"
                    ;;
                6)
                    exit
                    ;;
                *)
                    echo "Not a valid option, chose between 1 and 6"
                    package
                    ;;
            esac
            ;;
    esac
    if [ $PACK = "true" ]
    then
        ACTION="Preparing the installation"
        mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp > /dev/null 2>&1
        check_errors

        echo "Fill up realm (UPPERCASE)"   
        samba-tool domain provision --use-rfc2307 --interactive
        
        mv /etc/krb5.conf /etc/krb5.conf.bkp

        ACTION="Coping krb5.conf"
        cp /var/lib/samba/private/krb5.conf /etc/krb5.conf > /dev/null 2>&1
        check_errors

        ACTION="Daemon reload"
        systemctl daemon-reload > /dev/null 2>&1
        check_errors

        ACTION="Samba unmask"
        systemctl unmask samba-ad-dc > /dev/null 2>&1
        check_errors

        ACTION="Samba enable"
        systemctl enable samba-ad-dc > /dev/null 2>&1
        check_errors
    fi
}


#beginning
export LANG=en_US.UTF8
export LC_ALL=en_US.UTF8
yum install -y redhat-lsb-core 2> /dev/null
zypper --non-interactive install lsb-release 2> /dev/null


DISTRO=$(lsb_release -sd | sed 's/"//g' | tr [:upper:] [:lower:] | awk '{print $1}')
VERSION=$(lsb_release -sr | sed 's/\.//g')
DISTROVERSION=$DISTRO$VERSION

echo "What is your dc name?"
read NAME
hostnamectl set-hostname $NAME

start
package_or_build

echo "Would you like to update hosts, hostname and resolv.conf now?"
read ANSWER
yes_or_no $ANSWER
if [ "$?" = '1' ]
then
    prepare
else
    echo "ok"
fi

echo "Finished, rebooting, run samba2.sh after reboot"
echo "bye"
key

systemctl reboot