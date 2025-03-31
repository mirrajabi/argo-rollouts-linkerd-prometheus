#!/bin/bash

set -eu

# Make sure the slow cooker is not running
kubectl delete -f /opt/demo/test/slow-cooker.yaml -n apps || true

# Trigger a rollout and start calling endpoints that return error responses
kubectl argo rollouts set image myapp myapp=ghcr.io/mccutchen/go-httpbin:2.17.1 -n apps

# Monitor progress
kubectl argo rollouts get rollout myapp -n apps --watch
