# Progressive Canary Releases with Argo Rollouts Analysis and Linkerd Metrics

Link to the related article on my website: [https://mirrajabi.nl/posts/13-argo-rollout-analysis-with-linkerd-and-prometheus](https://mirrajabi.nl/posts/13-argo-rollout-analysis-with-linkerd-and-prometheus)

[![asciicast](https://asciinema.org/a/oS5s9XXIIZ7QR7t63EV5nRLdx.svg)](https://asciinema.org/a/oS5s9XXIIZ7QR7t63EV5nRLdx)

This repository demonstrates how to implement automatic rollbacks in a Kubernetes cluster using Argo Rollouts, Linkerd, and Prometheus. The setup includes:

- **Argo Rollouts**: A Kubernetes controller and set of CRDs that provide advanced deployment capabilities such as blue-green and canary deployments.
- **Linkerd**: A lightweight service mesh for Kubernetes that provides observability, reliability, and security features.
- **Prometheus**: A powerful monitoring and alerting toolkit that collects metrics from configured targets at specified intervals.

## How it works

- When a new version of the application is deployed, Argo Rollouts will start a canary rollout.
- The canary rollout lives side-by-side with the stable version of the application and will receive a percentage of the traffic.
- The percentage of the traffic gets increased until the canary version is fully deployed.
- Prometheus will collect metrics from the Linkerd.
- If the requests to the canary release are above a certain threshold, the rollout will be marked as failed and Argo Rollouts will automatically rollback to the previous stable version.
- If the requests to the canary release are below a certain threshold, the rollout will be marked as successful and the canary version will be promoted to stable.

## How to run the demo

The scripts in this repository take care of all of the pre-requisites so you can experience the demo without having to faff about with setting up the environment. 

There are multiple ways you can run the demo:

- (Recommended) Using [Multipass](https://multipass.run/): In this case, all you need to do is installing Multipass and the rest is taken cared of. The demo will be run in a VM and at the end you can destroy the VM and all the resources will be removed.
- Using [kind](https://kind.sigs.k8s.io/): In this case, you can run the scripts inside [vm-init folder](./vm-init/) to create the Kind cluster.

### Running the demo using Multipass (Recommended)

1. Install Multipass on your machine. You can find instructions for your OS [here](https://multipass.run/download).
1. Open a terminal in the root of the repository and run the following command to create a VM, install all the dependencies on it, and prepare the demo cluster:

    ```bash
    make create
    ```

1. Once the VM is created, you can run the following commands to simuate a successful/failed rollout:

    ```bash
    make rollout-success
    # or
    make rollout-failure
    ```

1. Once you are done with the demo, you can destroy the VM and all the resources will be removed by running:

    ```bash
    make destroy
    ```

### Running the demo using Kind

I don't recommend this method since it requires a lot of manual steps and may generate a bit of garbage on your machine. However, if you don't want to run the demo in a VM, you can run it in your local machine using Kind by following these steps:

1. Install Docker on your machine. You can find instructions for your OS [here](https://docs.docker.com/get-docker/).
1. Install Kind on your machine. You can find instructions for your OS [here](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).
1. Install Helm on your machine. You can find instructions for your OS [here](https://helm.sh/docs/intro/install/).
1. Install kubectl on your machine. You can find instructions for your OS [here](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/).
1. Install step-cli. This will be used to generate certificates.
1. Open a terminal in the root of the repository and run the following command to create a Kind cluster, install all the dependencies on it, and prepare the demo cluster:

    ```bash
    ./vm-init/prepare-demo.sh
    ```

1. Once the Kind cluster is created, you can run the following commands to simuate a successful/failed rollout:

    ```bash
    ./vm-init/simulate-successful-rollout.sh
    # or
    ./vm-init/simulate-failed-rollout.sh
    ```

1. Once you are done with the demo, you can destroy the Kind cluster and all the resources will be removed by running:

    ```bash
    ./vm-init/destroy.sh
    ```
