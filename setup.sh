#!/bin/sh
log() {
  printf "\033[33m$*\033[0m\n"
}

run() {
  printf "\033[32m$*\033[0m\n"
  "$@" || exit $?
}

log "Ensuring local folders to share with VMs exist"
[[ -d registry ]] || run mkdir -p registry
[[ -d share/vertcoin-data ]] || run mkdir -p share/vertcoin-data

if ! [[ -e share/vertcoin-data/vertcoin.conf ]]
then
  log "Generating password for vertcoind"
  if [[ -x md5 ]]
  then
    password=$(head -c 1024 /dev/urandom | md5)
  else
    password=$(head -c 1024 /dev/urandom | md5sum | cut -c 1-32)
  fi
  echo "rpcallowip=*" >> share/vertcoin-data/vertcoin.conf
  echo "rpcpassword=$password" >> share/vertcoin-data/vertcoin.conf
fi

if ! vagrant status registry | grep registry | grep running >/dev/null
then
  log "Starting registry VM"
  run vagrant up registry
fi

while ! vagrant ssh registry -c 'systemctl status docker-registry.service' 2>/dev/null | grep 'active (running)' >/dev/null
do
  log "Docker registry not started, can take a few minutes to download the docker image, will check again in 20 seconds..."
  sleep 20
done
log "Registry started"

if ! vagrant ssh registry -c 'docker pull registry.local/baseimage' >/dev/null 2>/dev/null
then
  log "Pulling phusion/baseimage 0.9.10 container"
  run vagrant ssh registry -c 'docker pull phusion/baseimage:0.9.10'

  log "Tagging container and pushing to local registry"
  run vagrant ssh registry -c "docker tag \$(docker images | grep phusion/baseimage | grep 0.9.10 | head -n 1 | awk '{ print \$3 }') registry.local/baseimage:0.9.10"
  run vagrant ssh registry -c 'docker push registry.local/baseimage:0.9.10'
fi

for file in dockerfiles/*
do
  container=$(basename $file)
  if [[ "$1" == "-rebuild" ]] || ! vagrant ssh registry -c "docker pull registry.local/$container" >/dev/null 2>/dev/null
  then
    log "Creating container for $container"
    run vagrant ssh registry -c "docker build -t registry.local/$container - < /tmp/dockerfiles/$container"

    log "Pushing container for $container"
    run vagrant ssh registry -c "docker push registry.local/$container"
  fi
done

log "Starting main VM"
run vagrant up master

log "====="
log "Everything is setup, your p2pool instance should be accessible soon on"
log "http://$(hostname -s):9174 and you can start pointing workers at it."
log "(although, it will just return 'No data received' until the blockchain"
log "is up to date)"
log
log "To update your images simply run"
log "    ./setup.sh -rebuild && vagrant reload master"
log
log "If you wish to reclaim space give the master time to pull the container"
log "images then run"
log "    vagrant destroy registry"
log "    rm -rf registry"
lag "this will result in a much higher rebuild time though"
