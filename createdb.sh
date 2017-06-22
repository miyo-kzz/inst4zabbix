#!/bin/bash

SQL_USER="root"
SQL_PASSWD=""
USE_PGSQL=0
USE_PASSWD=0
OS_DIST="rhel"

function init_db()
{
  local ret=0
  local cmd_args=""


  local arg_host=""
  local arg_auth=""
  local arg_exec=""

  if [ "$DBHost" != "localhost" -a -n "$DBHost" ]; then
    arg_host="-h $DBHost"
  fi
  if [ $USE_PGSQL -eq 0 ]; then
    # for MySQL
    if [ "$SQL_USER" != "" ]; then
      arg_auth="-u $SQL_USER"
    fi
    if [ $USE_PASSWD -eq 1 ]; then
      arg_auth+=" -p $SQL_PASSWD"
    fi
  else
    if [ "$SQL_USER" != "" ]; then
      arg_auth=" -U $SQL_USER"
    fi
  fi
  if [ "$OS_DIST" == "rhel" ]; then
    pkg_ver="$(rpm -q --qf "%{version}" $PKG_install)"

    sql_2x="$(rpm -ql $PKG_install | grep "/schema\.sql")"
    sql_3x="$(rpm -ql $PKG_install | grep "/create\.sql\.gz")"

    if [ ! -z $sql_2x ]; then
      sql_files="schema.sql images.sql data.sql"
      sql_dir="${sql_2x%/*}"
    elif [ ! -z $sql_3x ]; then
      sql_files="create.sql.gz"
      sql_dir="${sql_3x%/*}"
    fi
  fi

  create_db "$arg_host" "$arg_auth"
  for sql_file in $sql_files
  do
    create_table "$arg_host" "$arg_auth" ${sql_dir}/${sql_file}
  done

  return $ret
}

function create_db()
{
  local ret=0
  local host="$1"
  local auth="$2"
  local with_pw=""
  local sql="CREATE DATABASE $DBName"

  case $USE_PGSQL in
  0)
    if [ ! -z $DBPassword ]; then
      with_pw="IDENTIFIED BY \"${DBPassword}\""
    fi
    eval mysql $host $auth -e \
      \'CREATE DATABASE $DBName character set utf8 collate utf8_bin\'
    ret=$?
    eval mysql $host $auth -e \
      \'GRANT ALL PRIVILEGES ON ${DBName}.* TO ${DBUser}@${FromIP} $with_pw\'
    ;;
  1)
    if [ ! -z $DBPassword ]; then
      with_pw="-P"
    fi
    eval createuser $host $auth -R -S -D $with_pw $DBUser
    ret=$?
    eval createdb $host $auth -E UTF-8 -O $DBUser $DBName
    ;;
  esac
  ret=$((ret+$?))

  return $ret
}

function create_table()
{
  local ret=0
  local host="$1"
  local auth="$2"
  local file="$3"
  local cmd=""

  if [ $USE_PGSQL -eq 0 ]; then
    cmd="mysql"
  else
    cmd="psql -q"
    auth="-U $DBUser"
  fi
  cmd+=" $host $auth $DBName"

  case $file in
  *.sql)
    eval "cat $file | $cmd"
    ;;
  *.sql.gz)
    eval "gzip -dc $file | $cmd"
    ;;
  esac
  ret=$?

  return $ret
}

while [ $# -gt 0 ]
do
  case "$1" in
  -u)
    SQL_USER=$2
    shift
    ;;
  --user=*)
    SQL_USER="${1##*=}"
    ;;
  -p|--use-postgresql|--use-pgsql)
    USE_PGSQL=1
    ;;
  -M|--use-mysql)
    USE_PGSQL=0
    ;;
  -W)
    USE_PASSWD=1
    case "$2" in
    -*)
      ;;
    *)
      if [ "$PKG_core" != "" -o $# -gt 2 ]; then
        SQL_PASSWD="$2"
        shift
      fi
      ;;
    esac
    ;;
  --password=*)
    USE_PASSWD=1
    SQL_PASSWD="${1##*=}"
    ;;
  server|proxy)
    PKG_core="$1"
    ;;
  esac
  shift
done

CONFD_append="/etc/zabbix/zabbix_${PKG_core}.d"
CONF_append="${CONFD_append}/zabbix_${PKG_core}_append.conf"

eval $(grep ^DBName= $CONF_append | sed 's/\(.*=\)\(.*\)$/\1"\2"/')
eval $(grep ^DBHost= $CONF_append | sed 's/\(.*=\)\(.*\)$/\1"\2"/')
eval $(grep ^DBUser= $CONF_append | sed 's/\(.*=\)\(.*\)$/\1"\2"/')
eval $(grep ^DBPassword= $CONF_append | sed 's/\(.*=\)\(.*\)$/\1"\2"/')
eval $(grep ^ListenIP= $CONF_append | sed 's/\(.*=\)\(.*\)$/\1"\2"/')

case "$ListenIP" in
localhost|0.0.0.0|"")
  FromIP="localhost"
  ;;
*)
  FromIP="$ListenIP"
  ;;
esac

case $USE_PGSQL in
0)
  PKG_install="zabbix-${PKG_core}-mysql"
  CMD_SQL="mysql"
  ;;
1)
  PKG_install="zabbix-${PKG_core}-pgsql"
  CMD_SQL="psql"
  ;;
*)
  exit 1
  ;;
esac

init_db

