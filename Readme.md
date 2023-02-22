# samba4
>It's an Active Directory alternative
* [samba4 wiki][samba4-doc]
* [Requirements][samba4-req]

## Instalation
- Check for [file system support][samba4-fss]
- install operating system
- Choose a domain name
- Add to /etc/hosts
- Install [packages dependencies][samba4-dep]
- Install [Distribution-specific Package][samba4-pac]
- Or [Build Samba from Source][samba4-source]

### Debian 10 dependencies:

```
apt-get -y install \
    acl \
    apt-utils \
    attr \
    autoconf \
    bind9utils \
    binutils \
    bison \
    build-essential \
    ccache \
    chrpath \
    curl \
    debhelper \
    dnsutils \
    docbook-xml \
    docbook-xsl \
    flex \
    gcc \
    gdb \
    git \
    glusterfs-common \
    gzip \
    heimdal-multidev \
    hostname \
    htop \
    krb5-config \
    krb5-kdc \
    krb5-user \
    lcov \
    libacl1-dev \
    libarchive-dev \
    libattr1-dev \
    libavahi-common-dev \
    libblkid-dev \
    libbsd-dev \
    libcap-dev \
    libcephfs-dev \
    libcups2-dev \
    libdbus-1-dev \
    libglib2.0-dev \
    libgnutls28-dev \
    libgpgme11-dev \
    libicu-dev \
    libjansson-dev \
    libjs-jquery \
    libjson-perl \
    libkrb5-dev \
    libldap2-dev \
    liblmdb-dev \
    libncurses5-dev \
    libpam0g-dev \
    libparse-yapp-perl \
    libpcap-dev \
    libpopt-dev \
    libreadline-dev \
    libsystemd-dev \
    libtasn1-bin \
    libtasn1-dev \
    libtracker-sparql-2.0-dev \
    libunwind-dev \
    lmdb-utils \
    locales \
    lsb-release \
    make \
    mawk \
    mingw-w64 \
    patch \
    perl \
    perl-modules \
    pkg-config \
    procps \
    psmisc \
    python3 \
    python3-cryptography \
    python3-dbg \
    python3-dev \
    python3-dnspython \
    python3-gpg \
    python3-iso8601 \
    python3-markdown \
    python3-matplotlib \
    python3-pexpect \
    python3-pyasn1 \
    python3-setproctitle \
    rng-tools \
    rsync \
    sed \
    sudo \
    tar \
    tree \
    uuid-dev \
    wget \
    xfslibs-dev \
    xsltproc \
    zlib1g-dev

```
### Debian packages
```
apt-get install acl attr samba samba-dsdb-modules samba-vfs-modules winbind libpam-winbind libnss-winbind krb5-config krb5-user dnsutils

```
### Debian 10 source build
```
wget https://download.samba.org/pub/samba/stable/samba-4.15.13.tar.gz
tar xvzf samba-4.15.13.tar.gz
cd samba-4.15.13

./configure --prefix /usr --enable-fhs --enable-cups --sysconfdir=/etc --localstatedir=/var \
--with-privatedir=/var/lib/samba/private --with-piddir=/var/run/samba --with-automount \
--datadir=/usr/share --with-lockdir=/var/run/samba --with-statedir=/var/lib/samba  \
--with-cachedir=/var/cache/samba --with-systemd

make -j $(nproc)
make install
ldconfig
```
## Provisioning a Samba Active Directory

### Backup smb.conf
```
mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp 
```
### Provisioning:
```
samba-tool domain provision --use-rfc2307 --interactive
```
or
```
samba-tool domain provision --use-rfc2307 --realm=MY.LOCAL.DOMAIN --domain=my \
--server-role=dc --dns-backend=SAMBA_INTERNAL --adminpass=P@ssw0rd
```
### Kerberos config

```
mv /etc/krb5.conf /etc/krb5.conf.bkp
cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
```

### Samba-ad-dc service script (only if you builded from source)
```
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

```
### SElinux conf (only if SElinux is on - needed for centos)
```
chcon -u system_u -r object_r -t bin_t /usr/sbin/samba* 
```

### Samba-ad-dc service load
```
systemctl daemon-reload
systemctl unmask samba-ad-dc
systemctl enable samba-ad-dc
systemctl restart samba-ad-dc
```
* Change search (your.realm) and nameserver at /etc/resolv.conf to your local host ip
* add your host ip at /etc/hosts

### Resolv.conf
/etc/resolv.conf
```
nameserver 192.168.0.11 //server ip
search my.local.domain
```

### Create a reverse zone
>may need reboot system

```
samba-tool dns zonecreate <Your-AD-DNS-Server-IP-or-hostname> 0.168.192.in-addr.arpa -U Administrator
Password for [administrator@SAMDOM.EXAMPLE.COM]:
Zone 0.168.192.in-addr.arpa created successfully
```

## [Verifying DC DNS Record][dns-rec]
```
smbclient -L localhost -U Administrator
smbclient //localhost/netlogon -UAdministrator -c 'ls'
dig -t srv _ldap.tcp.my.local
dig -t srv _kerberos.tcp.my.local
dig -t a ad1.my.local
```
reboot and have fun

# Using the script samba.sh
```
git clone https://github.com/ramosgladson/samba4.git
cd samba4
# ./samba.sh
(change resolv.conf nameserver, may need reboot)
# ./samba2.sh
```

# Joining a Samba DC to an Existing Active Directory
- Check for [file system support][samba4-fss]
- install operating system
- Choose a domain name
- Add to /etc/hosts
- Install [packages dependencies][samba4-dep]
- Install [Distribution-specific Package][samba4-pac]
- Or [Build Samba from Source][samba4-source]

## Set nameservers to ad1 and localhost ip
>vim /etc/resolv.conf

```
nameserver 192.168.0.11
nameserver 192.168.0.12
search my.local
```

## Samba service
```
systemctl stop samba-ad-dc
```

## Backup smb.conf
```
# mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
```

## To verify the settings use the kinit command to request a Kerberos ticket for the domain administrator:
```
# kinit administrator
Password for administrator@SAMDOM.EXAMPLE.COM:
```

## To list Kerberos tickets:
```
# klist
Ticket cache: FILE:/tmp/krb5cc_0
Default principal: administrator@SAMDOM.EXAMPLE.COM

Valid starting       Expires              Service principal
24.09.2015 19:56:55  25.09.2015 05:56:55  krbtgt/SAMDOM.EXAMPLE.COM@SAMDOM.EXAMPLE.COM
	renew until 25.09.2015 19:56:53
```
## [Time Synchronisation][time-sync]
-Synchronize time linux

## [Join Domain][join]
```
samba-tool domain join my.local DC --option="dns forwarder=8.8.8.8" --dns-backend=SAMBA_INTERNAL --option='idmap_ldb:use rfc2307 = yes' --option="interfaces=lo ens18"
```


<!-- Mardown Links -->
[samba4-doc]: https://wiki.samba.org/index.php/Main_Page
[samba4-req]: https://wiki.samba.org/index.php/Operating_System_Requirements
[samba4-dep]: https://wiki.samba.org/index.php/Package_Dependencies_Required_to_Build_Samba
[samba4-pac]: https://wiki.samba.org/index.php/Distribution-specific_Package_Installation
[samba4-source]: https://wiki.samba.org/index.php/Build_Samba_from_Source
[samba4-fss]: https://wiki.samba.org/index.php/File_System_Support
[time-sync]: https://wiki.samba.org/index.php/Time_Synchronisation
[dns-rec]: https://wiki.samba.org/index.php/Verifying_and_Creating_a_DC_DNS_Record
[join]: https://wiki.samba.org/index.php/Joining_a_Samba_DC_to_an_Existing_Active_Directory#Joining_the_Active_Directory_as_a_Domain_Controllerhttps://wiki.samba.org/index.php/Joining_a_Samba_DC_to_an_Existing_Active_Directory#Joining_the_Active_Directory_as_a_Domain_Controller
[realm]: /_images/realm.png
[krbsrv]: /_images/krbsrv.png
[krbadm]: /_images/krbadm.png
[dhcp]: /_images/dhcp.png
