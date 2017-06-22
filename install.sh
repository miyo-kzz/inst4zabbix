#!/bin/bash

INST_BASE="https://github.com/miyo-kzz/inst4zabbix"
REPO_BASE="http://repo.zabbix.com/zabbix"

INSTALLERS=" \
  install-server.sh \
  install-proxy.sh \
  install-agent.sh \
  createdb.sh \
  function-common.sh \
  "
ARCH="x86_64"
OS_DIST="rhel"
ZBX_VERSION="3.0"
DISABLE_EPEL=""

ALLOW_ROOT=0
PROXY_MODE=0
USE_JMX=0
USE_PGSQL=0
WITH_AGENT=0

function usage()
{
  cat << EOL
Usage: $0 [options] target

  options
    -a, --with-agent
    -j, --use-java-gateway, --use-jmx
    -r, --allow-root
    -V, --zabbix-version
    -p, --use-postgresql, --use-pgsql
    -P, --enable-passive-proxy, --enable-pasv-proxy

  target
    agent
    proxy
    server

EOL
  return 0
}

function get_version()
{
  local os_version=""

  if [ -f /etc/os-release ]; then
    . /etc/os-release
    os_version="${VERSION_ID%%.*}"
  elif [ -f /etc/redhat-release ]; then
    os_version="$(sed 's/.*release \([0-9]\)\..*$/\1/' /etc/redhat-release)"
  fi
  echo $os_version

  return 0
}

function get_repository()
{
  local ret=0

  case $OS_DIST in
  rhel)
    yum -y install $DL_URL
    ret=$?
    ;;
  *)
    echo "$OS_DIST is not supported."
    ;;
  esac

  return $ret
}

function get_installer()
{
  local ret=0
  local script=""

  for script in $INSTALLERS
  do
    if [ ! -f $script ]; then
      curl -L -O ${INST_BASE}/raw/master/$script
      ret=$((ret+$?))
      chmod +x $script
    fi
  done

  return $ret
}

while [ $# -gt 0 ];
do
  case "$1" in
  -h|--help)
    usage
    exit 1
    ;;
  -a|--with-agent)
    WITH_AGENT=1
    ;;
  -j|--use-jmx)
    USE_JMX=1
    ;;
  -r|--allow-root)
    ALLOW_ROOT=1
    ;;
  -p|--use-postgresql|--use-pgsql)
    USE_PGSQL=1
    ;;
  -V)
    ZBX_VERSION=$2
    shift
    ;;
  --zabbix-version=*)
    ZBX_VERSION=${1##*=}
    ;;
  -P|--enable-passive-proxy|--enable-pasv-proxy)
    PROXY_MODE=1
    ;;
  agent|proxy|server)
    installer="install-${1}.sh"
    ;;
  *)
    echo "$0: invalid option - '$1'"
    exit 1
    ;;
  esac
  shift
done

OS_VER="$(get_version)"
case "$OS_DIST" in
rhel)
  if [ $(yum repolist | grep -c epel) -ne 0 ]; then
    DISABLE_EPEL="--disablerepo=epel"
  fi
  OS_RELEASE="el${OS_VER}"
  REPO_NAME="zabbix-release-${ZBX_VERSION}-1.${OS_RELEASE}.noarch.rpm"
  DL_URL="${REPO_BASE}/${ZBX_VERSION}/${OS_DIST}/${OS_VER}/${ARCH}/${REPO_NAME}"
  ;;
*)
  # not supported
  ;;
esac

export ZBX_VERSION OS_VER OS_RELEASE OS_DIST DL_URL INST_BASE DISABLE_EPEL
export ALLOW_ROOT USE_JMX USE_PGSQL PROXY_MODE WITH_AGENT

get_repository
get_installer
./$installer

exit

