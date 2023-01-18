# samba4
>It's an Active Directory alternative
* [samba4 wiki][samba4-doc]
* [Requirements][samba4-req]

## Instalation
- Check for [file system support][samba4-fss]
- install operating system
- Choose a domain name
- Add to /etc/hosts
- Install [packages][samba4-pac]

### Debian 10 example:

```
# apt-get install acl attr autoconf bind9utils bison build-essential \
debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user \
libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev \
libcap-dev libcups2-dev libgnutls28-dev libgpgme-dev libjson-perl libldap2-dev \
libncurses5-dev libpam0g-dev libparse-yapp-perl libpopt-dev libreadline-dev \
nettle-dev perl perl-modules pkg-config   python-all-dev python-crypto python-dbg \
python-dev python-dnspython   python3-dnspython python-gpg python3-gpg \
python-markdown python3-markdown python3-dev xsltproc zlib1g-dev liblmdb-dev \
lmdb-utils acl attr samba samba-dsdb-modules samba-vfs-modules winbind krb5-config \
krb5-user dnsutils smbclient 

```
Set realm ALL CAPS
![][realm]

Set servers
![][krbsrv]

Set kerberos adm
![][krbadm]


### If any mistake was made, it's possible to reconfigure
```
# vim /etc/krb5.conf to be like that:

[realms]
	MY.LOCAL.DOMAIN = {
		kdc = zero0.my.local.domain
		kdc = zero1.my.local.domain
		admin_server = zero0.my.local.domain
	}
	ATHENA.MIT.EDU = {
    [...]
```
## Provisioning a Samba Active Directory

### Backup smb.conf
```
# mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
```
### Provisioning:
```
# samba-tool domain provision --use-rfc2307 --interactive
```
or
```
# samba-tool domain provision --use-rfc2307 --realm=MY.LOCAL.DOMAIN --domain=my \
--server-role=dc --dns-backend=SAMBA_INTERNAL --adminpass=P@ssw0rd
```

### Samba-ad-dc service
```
# systemctl unmask samba-ad-dc
# systemctl enable samba-ad-dc
# systemctl restart samba-ad-dc
```
* Change name server at /etc/resolv.conf to your local host ip
* add your host ip at /etc/hosts

### Resolv.conf
/etc/resolv.conf
```
nameserver 192.168.0.11 //server ip
search my.local.domain
```

### Create a reverse zone
```
# samba-tool dns zonecreate <Your-AD-DNS-Server-IP-or-hostname> 0.168.192.in-addr.arpa -U Administrator
Password for [administrator@SAMDOM.EXAMPLE.COM]:
Zone 0.168.192.in-addr.arpa created successfully
```

## Testing
```
# smbclient -L localhost -U Administrator
# smbclient //localhost/netlogon -UAdministrator -c 'ls'
# dig -t srv _ldap.tcp.my.local
# dig -t srv _kerberos.tcp.my.local
# dig -t a ad1.my.local
# kinit Administrator
```
reboot and have fun

# Using the script samba.sh
```
# git clone https://github.com/ramosgladson/samba4.git
# cd samba4
# ./samba.sh
(change resolv.conf nameserver)
# ./samba2.sh
```

# Joining a Samba DC to an Existing Active Directory
```
# apt-get install acl attr autoconf bind9utils bison build-essential debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev libcap-dev libcups2-dev libgnutls28-dev libgpgme-dev libjson-perl libldap2-dev libncurses5-dev libpam0g-dev libparse-yapp-perl libpopt-dev libreadline-dev nettle-dev perl perl-modules pkg-config   python-all-dev python-crypto python-dbg python-dev python-dnspython   python3-dnspython python-gpg python3-gpg python-markdown python3-markdown python3-dev xsltproc zlib1g-dev liblmdb-dev lmdb-utils acl attr samba samba-dsdb-modules samba-vfs-modules winbind krb5-config krb5-user dnsutils smbclient
```
![][dhcp]

## Set nameservers to ad1 and localhost ip
```
# vim /etc/resolv.conf

nameserver 192.168.0.11
nameserver 192.168.0.12
search my.local
```

## Set the following settings in your Kerberos client configuration file /etc/krb5.conf:

```
[libdefaults]
    dns_lookup_realm = false
    dns_lookup_kdc = true
    default_realm = MY.LOCAL
    
[realms]
	MY.LOCAL.DOMAIN = {
		kdc = ad1.my.local
		kdc = ad1.my.local
		admin_server = ad1.my.local
	}
	ATHENA.MIT.EDU = {
    [...]

```
## Backup smb.conf
```
# mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
```
## Samba service
```
# systemctl stop samba-ad-dc
# systemctl unmask samba-ad-dc
# systemctl enable samba-ad-dc
# systemctl restart samba-ad-dc
```
## Join Domain
```
samba-tool domain join my.local DC --option="dns forwarder=8.8.8.8" --dns-backend=SAMBA_INTERNAL --option='idmap_ldb:use rfc2307 = yes' --option="interfaces=lo ens18"
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




<!-- Mardown Links -->
[samba4-doc]: https://wiki.samba.org/index.php/Main_Page
[samba4-req]: https://wiki.samba.org/index.php/Operating_System_Requirements
[samba4-pac]: https://wiki.samba.org/index.php/Package_Dependencies_Required_to_Build_Samba
[samba4-fss]: https://wiki.samba.org/index.php/File_System_Support
[realm]: /_images/realm.png
[krbsrv]: /_images/krbsrv.png
[krbadm]: /_images/krbadm.png
[dhcp]: /_images/dhcp.png
