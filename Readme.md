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

Ubuntu 20.04 example:

```
$ sudo apt-get install acl attr autoconf bind9utils bison build-essential \
debhelper dnsutils docbook-xml docbook-xsl flex gdb libjansson-dev krb5-user \
libacl1-dev libaio-dev libarchive-dev libattr1-dev libblkid-dev libbsd-dev \
libcap-dev libcups2-dev libgnutls28-dev libgpgme-dev libjson-perl libldap2-dev \
libncurses5-dev libpam0g-dev libparse-yapp-perl libpopt-dev libreadline-dev \
nettle-dev perl perl-modules pkg-config   python-all-dev python-crypto python-dbg \
python-dev python-dnspython   python3-dnspython python-gpg python3-gpg \
python-markdown python3-markdown python3-dev xsltproc zlib1g-dev liblmdb-dev \
lmdb-utils acl attr samba samba-dsdb-modules samba-vfs-modules winbind krb5-config \
krb5-user dnsutils
```
Set realm ALL CAPS
![][realm]

Set servers
![][krbsrv]

Set kerberos adm
![][krbadm]


If any mistake was made, it's possible to reconfigure
```
dpkg-reconfigure krb5-config
```
or edit /etc/krb5.conf to be like that:

```
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

Backup smb.conf
```
# mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp
```
Provisioning:
```
# samba-tool domain provision --use-rfc2307 --interactive
```
or
```
# samba-tool domain provision --use-rfc2307 --realm=MY.LOCAL.DOMAIN --domain=my \
--server-role=dc --dns-backend=SAMBA_INTERNAL --adminpass=P@ssw0rd
```
reboot and have fun

<!-- Mardown Links -->
[samba4-doc]: https://wiki.samba.org/index.php/Main_Page
[samba4-req]: https://wiki.samba.org/index.php/Operating_System_Requirements
[samba4-pac]: https://wiki.samba.org/index.php/Package_Dependencies_Required_to_Build_Samba
[samba4-fss]: https://wiki.samba.org/index.php/File_System_Support
[realm]: /_images/realm.png
[krbsrv]: /_images/krbsrv.png
[krbadm]: /_images/krbadm.png
