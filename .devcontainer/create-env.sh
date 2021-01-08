#!/bin/bash

# References:
# https://bosh.io/docs/bosh-lite/

# To run bosh CLI using docker cpi:
# https://github.com/cloudfoundry-attic/bosh-lite/issues/439#issuecomment-348329967

export BOSH_LOG_LEVEL=none
bosh create-env /bosh-deployment/bosh.yml \
  -o /bosh-deployment/docker/cpi.yml \
  -o /bosh-deployment/docker/unix-sock.yml \
  -o /bosh-deployment/jumpbox-user.yml \
  --state=/workspace/state.json              \
  --vars-store /workspace/creds.yml          \
  -v director_name=docker \
  -v internal_cidr=10.245.0.0/16 \
  -v internal_gw=10.245.0.1 \
  -v internal_ip=10.245.0.10 \
  -v docker_host=unix:///var/run/docker.sock \
  -v network=net3
##
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int /workspace/creds.yml --path /admin_password`
bosh alias-env bosh-in-docker -e 10.245.0.10 --ca-cert <(bosh int /workspace/creds.yml --path /director_ssl/ca)

bosh -n -e bosh-in-docker update-cloud-config /bosh-deployment/docker/cloud-config.yml -v network=net3

# Docker CPI - Cannot upload stemcell due to "Cannot connect to the Docker daemon... Is the docker daemon running?"
# https://github.com/cloudfoundry/bosh-deployment/issues/94
chmod 777 /var/run/docker.sock

bosh -e bosh-in-docker upload-stemcell \
  https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-xenial-go_agent?v=315.45 \
  --sha1 674cd3c1e64d8c51e62770697a63c07ca04e9bbd

bosh -n -e bosh-in-docker -d zookeeper deploy /zookeeper.yml
bosh -e bosh-in-docker -d zookeeper run-errand smoke-tests
