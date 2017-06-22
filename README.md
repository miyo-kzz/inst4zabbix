Easy installer for Zabbix
====

NAME
----

install.sh, createdb.sh - Easy installer for Zabbix

DESCRIPTION
----

install.sh install Zabbix components.  
createdb.sh create database for Zabbix sever and Zabbix proxy.

REQUIREMENT
----

* Supported operating system
  - [x] Redhat Enterprise Linux 5, 6, 7 and clone OS.
  - [ ] Ubuntu
  - [ ] Debian

* Supported database server
  - [x] MySQL, MariaDB
  - [x] PostgreSQL

INSTALLATION
----

see [Wiki pages](https://github.com/miyo-kzz/inst4zabbix/wiki/installation).

SYNOPSIS
----

install.sh [OPTIONS] TARGET  
createdb.sh [OPTIONS] TARGET

OPTIONS
----

* -a, --with-agent  
Only install.sh  
Install with zabbix-agent.

* -p, --use-postgresql, --use-pgsql  
Use PostgreSQL for database server. Default database server is MySQL.

* -r, --allow-root  
Only install.sh  
Set AllowRoot to allow (AllowRoot=1). Default value is '0' (not allow root).

* -u USERNAME, --user=USERNAME  
Only createdb.sh  
Input a username for connecting to a database.

* -W PASSWORD, --password=PASSWORD  
Input a password before connecting to a database.

* -P, --enable-passive-proxy, --enable-pasv-proxy  
Only install.sh  
Set ProxyMode to passive mode (ProxyMode=1). Default mode is '0' (active).

* -V VERSION, --zabbix-version=VERSION  
Only install.sh  
Set major version for Zabbix (e.g. 2.2, 3.0, 3.2). Default version is '3.0'.

TARGET
----

* agent  
Install Zabbix agent.

* proxy  
Install Zabbix proxy.

* server  
Install Zabbix server.

UNSOLVED ISSUES
----

* Does not support Ubuntu and Debian packages.

* Does not support uninstallation.

AUTHOR
----

[K.Miyoshi](mailto:miyoshi.kzz@zeronet.gr.jp)

LICENSE
----

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)

FILES
----

install.sh, install-server.sh, install-agent.sh, install-proxy.sh,
createdb.sh, function-common.sh

