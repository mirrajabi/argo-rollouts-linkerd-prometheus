#!/bin/bash

set -eu

# Create Kind cluster
kind create cluster --config=/opt/demo/cluster.yaml --name rollouts-playground-cluster

# Install Linkerd
helm repo add linkerd-edge https://helm.linkerd.io/edge
helm install linkerd-crds linkerd-edge/linkerd-crds \
  -n linkerd --create-namespace

# Generate mTLS certs: https://linkerd.io/2-edge/tasks/generate-certificates/
mkdir -p /opt/linkerd-certs
step certificate create root.linkerd.cluster.local /opt/linkerd-certs/ca.crt /opt/linkerd-certs/ca.key \
  --profile root-ca --no-password --insecure
step certificate create identity.linkerd.cluster.local /opt/linkerd-certs/issuer.crt /opt/linkerd-certs/issuer.key \
  --profile intermediate-ca --not-after 8760h --no-password --insecure \
  --ca /opt/linkerd-certs/ca.crt --ca-key /opt/linkerd-certs/ca.key

helm install linkerd-control-plane \
  -n linkerd \
  --set-file identityTrustAnchorsPEM=/opt/linkerd-certs/ca.crt \
  --set-file identity.issuer.tls.crtPEM=/opt/linkerd-certs/issuer.crt \
  --set-file identity.issuer.tls.keyPEM=/opt/linkerd-certs/issuer.key \
  linkerd-edge/linkerd-control-plane

# linkerd viz install | kubectl apply -f -
# kubectl wait --for=condition=available -n linkerd-viz deploy/web --timeout=10m
# SMI support
helm repo add l5d-smi https://linkerd.github.io/linkerd-smi
helm install l5d-smi/linkerd-smi --generate-name

# Install Argo Rollouts
kubectl create namespace argo-rollouts
helm repo add argo https://argoproj.github.io/argo-helm
helm install argo-rollouts argo/argo-rollouts -n argo-rollouts
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-arm64
chmod +x kubectl-argo-rollouts-linux-arm64
sudo mv kubectl-argo-rollouts-linux-arm64 /usr/local/bin/kubectl-argo-rollouts


# Install Prometheus with Linkerd integration
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
cat <<EOF | helm upgrade --install prometheus prometheus-community/prometheus -n monitoring --create-namespace -f -
alertmanager:
  enabled: false
kubeStateMetrics:
  enabled: false
nodeExporter:
  enabled: false
pushgateway:
  enabled: false
server:
  global:
    scrape_interval: 10s
    scrape_timeout: 10s
    evaluation_interval: 10s
  persistentVolume:
    enabled: false
extraScrapeConfigs: |
  - job_name: 'linkerd-controller'
    kubernetes_sd_configs:
    - role: pod
      namespaces:
        names:
        - 'linkerd'
        - 'linkerd-viz'
    relabel_configs:
    - source_labels:
      - __meta_kubernetes_pod_container_port_name
      action: keep
      regex: admin-http
    - source_labels: [__meta_kubernetes_pod_container_name]
      action: replace
      target_label: component

  - job_name: 'linkerd-service-mirror'
    kubernetes_sd_configs:
    - role: pod
    relabel_configs:
    - source_labels:
      - __meta_kubernetes_pod_label_component
      - __meta_kubernetes_pod_container_port_name
      action: keep
      regex: linkerd-service-mirror;admin-http$
    - source_labels: [__meta_kubernetes_pod_container_name]
      action: replace
      target_label: component

  - job_name: 'linkerd-proxy'
    kubernetes_sd_configs:
    - role: pod
    relabel_configs:
    - source_labels:
      - __meta_kubernetes_pod_container_name
      - __meta_kubernetes_pod_container_port_name
      - __meta_kubernetes_pod_label_linkerd_io_control_plane_ns
      action: keep
      regex: ^linkerd-proxy;linkerd-admin;linkerd$
    - source_labels: [__meta_kubernetes_namespace]
      action: replace
      target_label: namespace
    - source_labels: [__meta_kubernetes_pod_name]
      action: replace
      target_label: pod
    # special case k8s' "job" label, to not interfere with prometheus' "job"
    # label
    # __meta_kubernetes_pod_label_linkerd_io_proxy_job=foo =>
    # k8s_job=foo
    - source_labels: [__meta_kubernetes_pod_label_linkerd_io_proxy_job]
      action: replace
      target_label: k8s_job
    # drop __meta_kubernetes_pod_label_linkerd_io_proxy_job
    - action: labeldrop
      regex: __meta_kubernetes_pod_label_linkerd_io_proxy_job
    # __meta_kubernetes_pod_label_linkerd_io_proxy_deployment=foo =>
    # deployment=foo
    - action: labelmap
      regex: __meta_kubernetes_pod_label_linkerd_io_proxy_(.+)
    # drop all labels that we just made copies of in the previous labelmap
    - action: labeldrop
      regex: __meta_kubernetes_pod_label_linkerd_io_proxy_(.+)
    # __meta_kubernetes_pod_label_linkerd_io_foo=bar =>
    # foo=bar
    - action: labelmap
      regex: __meta_kubernetes_pod_label_linkerd_io_(.+)
    # Copy all pod labels to tmp labels
    - action: labelmap
      regex: __meta_kubernetes_pod_label_(.+)
      replacement: __tmp_pod_label_\$1
    # Take \`linkerd_io_\` prefixed labels and copy them without the prefix
    - action: labelmap
      regex: __tmp_pod_label_linkerd_io_(.+)
      replacement:  __tmp_pod_label_\$1
    # Drop the \`linkerd_io_\` originals
    - action: labeldrop
      regex: __tmp_pod_label_linkerd_io_(.+)
    # Copy tmp labels into real labels
    - action: labelmap
      regex: __tmp_pod_label_(.+)
EOF
sleep 30  # Wait for Prometheus

# Create apps namespace and application
kubectl create namespace apps
kubectl annotate namespace apps linkerd.io/inject=enabled
kubectl apply -n apps -f /opt/demo/app
