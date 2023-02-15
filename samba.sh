#!/bin/bash

############################################################################
#title           :sambar SCRIPT
#description     :Thir SCRIPT will prepair samba4 domain controller
#author	 	 :Gladson Carneiro Ramos
#date            :2023-02-12
#version         :1.1
#usage		 :bash samba4.sh
############################################################################

build_sh(){
cat << EOF > build.sh
#!/bin/bash

./configure --prefix /usr --enable-fhs --enable-cups --sysconfdir=/etc --localstatedir=/var \
--with-privatedir=/var/lib/samba/private --with-piddir=/var/run/samba --with-automount \
--datadir=/usr/share --with-lockdir=/var/run/samba --with-statedir=/var/lib/samba  \
--with-cachedir=/var/cache/samba --with-systemd

make -j $(nproc)
make install
ldconfig
EOF
}

service(){
cat << EOF > samba-ad-dc.service
[Unit]
Description=Samba Active Directory Domain Controller
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
ExecStart=/usr/local/samba/sbin/samba -D
PIDFile=/usr/local/samba/var/run/samba.pid
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
}

prepare(){
    echo "What is your dc name?"
    read NAME
    hostnamectl set-hostname $NAME
    IP=`ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d / -f 1`  
    echo "What is your domain (my.domain.com)"
    read MYDOMAIN
    mv /etc/resolv.conf /etc/resolv.conf.bkp
    echo "nameserver $IP" >> /etc/resolv.conf
    echo "search $MYDOMAIN" >> /etc/resolv.conf
    echo "$IP $NAME.$MYDOMAIN $NAME" >> /etc/hosts
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
	if [ $? -ne 0 ] ; then
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
    if [[ "$?" = '1' ]]; then
        install_dependencies
    else
        echo "Are you sure?"
        read ANSWER
        yes_or_no $ANSWER
        if [[ "$?" = '1' ]]; then
            echo "ok"
        else
            install_dependencies
        fi
    fi
}

install_dependencies(){
    if [ -e _dependencies/bootstrap_generated-dists_${DISTROVERSION}_bootstrap.sh ]; then
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
            if [[ $OPT = $i ]]; then
                DISTROVERSION=$SCRIPT                
                install_dependencies
            valid=true
            else
            valid=false
            fi
        done
        if [valid = "false"]; then
            echo "Would you like to abort script?"
            read ANSWER
            yes_or_no $ANSWER
            if [[ "$?" = '1' ]]; then
                exit
            fi
            echo "Please inform packages now:"
            read DEPENDENCIES
            case $DISTRO in 
                Ubuntu)
                    apt update -y && apt upgrade -y
                    apt install $DEPENDENCIES
                    ;;
                Debian)
                    apt update -y && apt upgrade -y
                    apt install $DEPENDENCIES
                    ;;
                Centos)
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

   
    if [[ $DISTRO = 'Ubuntu' ]]; then 
        case $VERSION in
            18.04)
                wget https://download.samba.org/pub/samba/stable/samba-4.17.5.tar.gz
                ;;
            
            20.04)
                wget https://download.samba.org/pub/samba/stable/samba-4.17.5.tar.gz
                ;;                    
            *)
                echo "Distro/version not found, witch samba version would you like to install (entire name please)?"
                curl https://download.samba.org/pub/samba/stable/ | grep tar.gz | awk '{print $8}' | cut -d'"' -f2 | grep samba-4.1
                read SAMBA
                wget https://download.samba.org/pub/samba/stable/${SAMBA}
                ;;
            
        esac

    elif [[ $DISTRO = 'Debian' ]]; then
        case $VERSION in
            10)
                wget https://download.samba.org/pub/samba/stable/samba-4.15.13.tar.gz
                ;;
            
            11)
                wget https://download.samba.org/pub/samba/stable/samba-4.17.5.tar.gz
                ;;
            *)
                echo "Distro/version not found, witch samba version would you like to install (entire name please)?"
                curl https://download.samba.org/pub/samba/stable/ | grep tar.gz | awk '{print $8}' | cut -d'"' -f2 | grep samba-4.1
                read SAMBA
                wget https://download.samba.org/pub/samba/stable/${SAMBA}
                ;;
        esac

    elif [[ $DISTRO = 'Centos' ]]; then
        case $VERSION in
            7)
                wget https://download.samba.org/pub/samba/stable/samba-4.17.5.tar.gz
                ;;
            
            8)
                wget https://download.samba.org/pub/samba/stable/samba-4.15.13.tar.gz
                ;;
            *)
                echo "Distro/version not found, witch samba version would you like to install (entire name please)?"
                curl https://download.samba.org/pub/samba/stable/ | grep tar.gz | awk '{print $8}' | cut -d'"' -f2 | grep samba-4.1
                read SAMBA
                wget https://download.samba.org/pub/samba/stable/${SAMBA}
                ;;
        esac        
    else
        echo "Distro/version not found, witch samba version would you like to install (entire name please)?"
        curl https://download.samba.org/pub/samba/stable/ | grep tar.gz | awk '{print $8}' | cut -d'"' -f2 | grep samba-4.1
        read SAMBA
        wget https://download.samba.org/pub/samba/stable/${SAMBA}
    fi

    tar xvzf samba-*.tar.gz
    build_sh
    mv build.sh `ls -l | grep d | awk '{print $9}' | grep ^samba`/
    chmod +x `ls -l | grep d | awk '{print $9}' | grep ^samba`/build.sh
    echo "run ./build.sh and exit"    
    cd `ls -l | grep d | awk '{print $9}' | grep ^samba`
    $SHELL
        
}



package(){
    case $DISTRO in
        Ubuntu)
            apt-get install acl attr samba samba-dsdb-modules samba-vfs-modules winbind libpam-winbind libnss-winbind krb5-config krb5-user dnsutils
            ;;
        Debian)
            apt-get install acl attr samba samba-dsdb-modules samba-vfs-modules winbind libpam-winbind libnss-winbind krb5-config krb5-user dnsutils
            ;;
        openSUSE)
            zypper install samba samba-winbind samba-ad-dc
            ;;
        *)
            echo "Would you like to install freeBSD samba-ad packages?"
            read ANSWER
            yes_or_no $ANSWER
            if [[ "$?" = '1' ]]; then
                pkg install net/samba44
            else
                echo "Red Hat does not provide packages for running Samba as an AD DC. As an alternative build samba-ad"
                build
            fi
            ;;
    esac
   
}


#beginning


DISTRO=$(lsb_release -si)
VERSION=$(lsb_release -sr)
DISTROVERSION=`echo $DISTRO$VERSION | sed 's/\.//g' | tr [:upper:] [:lower:]`

start
package_or_build


#ACTION="Preparing the installation"
#sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp > /dev/null 2>&1
#check_errors

service
mv samba-ad-dc.service /lib/systemd/system/
ln -s /lib/systemd/system/samba-ad-dc.service /etc/systemd/system/samba-ad-dc.service

echo "Fill up realm ALL CAPS"
key    
sudo samba-tool domain provision --use-rfc2307 --interactive

ACTION= "Coping krb5.conf"
cp /var/lib/samba/private/krb5.conf /etc/krb5.conf > /dev/null 2>&1
check_errors

ACTION="Daemon reload"
systemctl daemon-reload > /dev/null 2>&1
check_errors

ACTION="Samba unmask"
sudo systemctl unmask samba-ad-dc > /dev/null 2>&1
check_errors


ACTION="Samba enable"
sudo systemctl enable samba-ad-dc > /dev/null 2>&1
check_errors

echo "Have you prepared hosts, hostname and resolv.conf?"
read ANSWER
yes_or_no $ANSWER
if [[ "$?" = '1' ]]; then
    echo "ok"
else
    prepare
fi

echo "Finished, rebooting, run samba2.sh after reboot"
echo "bye"
key

sudo reboot
