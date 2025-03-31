#!/usr/bin/env bash

set -eu

multipass launch \
  --name rollouts-playground \
  --cpus 2 \
  --memory 4G \
  --disk 20G \
  --network en0 \
  --mount ./vm-init:/opt/init \
  --mount ./demo-cluster:/opt/demo \
  22.04

multipass exec rollouts-playground -- bash -c "/opt/init/prepare-vm.sh"
multipass exec rollouts-playground -- bash -c "sudo /opt/init/prepare-demo.sh"
