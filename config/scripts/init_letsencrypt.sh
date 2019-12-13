#!/bin/bash
set -e

RET=0
HOST_DOMAIN="host.docker.internal"
ping -q -c1 $HOST_DOMAIN > /dev/null 2>&1 || RET=$?
if [ $RET -ne 0 ]; then
  HOST_IP=$(ip route | awk 'NR==1 {print $3}')
  echo -e "$HOST_IP\t$HOST_DOMAIN" >> /etc/hosts
fi

LOCKFILE=$LETSENCRYPT_HOME/.lock

echo "Checking if vars set for letsencrypt..."
echo "LETSENCRYPT_HOME: $LETSENCRYPT_HOME"
echo "LOCKFILE: $LOCKFILE"
echo "WEBMASTER_MAIL: $WEBMASTER_MAIL"

# init only if lets-encrypt is running for the first time and if DOMAINS was set
if ([ ! -d $LETSENCRYPT_HOME ] || [ ! "$(ls -A "$LOCKFILE")" ]) && [ -n "$DOMAINS" ]; then
  echo "We are ready to give certs for $DOMAINS"
  /run_letsencrypt.sh --domains $DOMAINS
  touch "$LOCKFILE"
  echo "Letsencrypt first init done! killing apache that has been started by us..."
  killall -9 apache2
else
  echo "Skipping certs for $DOMAINS"
fi
