#!/bin/bash

set -eu

# Trigger a rollout and start calling endpoints that return error responses
kubectl argo rollouts set image myapp myapp=ghcr.io/mccutchen/go-httpbin:2.18 -n apps
# Slow cooker will call endpoints that return error responses
# That will cause the rollout to fail
kubectl apply -f /opt/demo/test/slow-cooker.yaml -n apps

# Monitor progress
kubectl argo rollouts get rollout myapp -n apps --watch
