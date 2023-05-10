---
excerpt_separator: "<!--more-->"
categories:
  - Kubernetes
tags:
  - Kubernetes
  - Jupyter
  - JupyterHub
  - Keycloak
title: JupyterHub on Baremetal Kubernetes - Part 1 - Setting up cluster
toc: true
---
# Introduction

In this blog post, we will guide you through the process of setting up a baremetal Kubernetes cluster tailored specifically for the Neural Transmissions (NETS)[^1] lab, using NVIDIA DeepOps. JupyterHub, a multi-user server that manages and proxies multiple instances of the Jupyter notebook server, is a perfect fit for this research environment. It facilitates seamless collaboration and sharing of data science projects among researchers. Throughout this tutorial, we will walk you through the steps to set up a Kubernetes cluster on baremetal servers equipped with NVIDIA GPUs, and get it ready for the deployment of JupyterHub.

[^1]: The Neural Transmissions (NETS) Lab is part of the Department of Mathematical Sciences at the Florida Institute of Technology. The lab focuses on developing deep learning models, explainable AI, traditional machine learning, and statistical analysis applied to various domains. For more information, visit [https://research.fit.edu/nets/](https://research.fit.edu/nets/).

# Prerequisites

Before we begin, ensure that you have the following:

1. A few baremetal servers with NVIDIA GPUs (e.g., Tesla, A100, or V100) and Ubuntu 18.04 or later installed.
2. A provision machine with Ubuntu 18.04 or later installed (can be one of the cluster node).
3. SSH access to the servers and root privileges.
4. NVIDIA GPU drivers installed on the servers.
5. Basic knowledge of Kubernetes and JupyterHub.

# Setting up the Kubernetes Cluster with NVIDIA DeepOps

For this deployment we patch DeepOps using [this repo](https://github.com/NEural-TransmissionS/NETS-deepops-patch) to deploy due to a [configuration bug in Kubespray](https://github.com/cert-manager/cert-manager/issues/2640#issuecomment-601872165), which affects `cert-manager` and potentially other services to communicate via `.svc` and `.cluster.local` DNS names.

## Step 1: Install DeepOps

First, let's set up a provision machine, which will run DeepOps and Kubespray to deploy the Kubernetes cluster. You can use one of the cluster nodes or a separate machine running Ubuntu 18.04 or later (in this tutorial we'll be using a cluster master node for provisioning). SSH into the provision machine and run the following commands:

```bash
cd ~
git clone https://github.com/NVIDIA/deepops
cd deepops
./scripts/setup.sh
```

This will install Ansible other required dependencies on the provision machine. Now we will clone the `NETS-deepops-patch` repo and patch DeepOps:

```bash
cd ~
git clone https://github.com/NEural-TransmissionS/NETS-deepops-patch
cd NETS-deepops-patch
./patch.sh
```

Next, we will configure the cluster.

## Step 2: Configure the cluster

### Configure inventory

Edit `config/inventory`. Add the nodes to the inventory file, specifying their respective hostnames or IP addresses, like following:

```ini
[all]
# current provision node is master node
# n0k0m3-master is localhost defined in /etc/hosts
n0k0m3-master ansible_host=<node-ip>
n0k0m3-node01 ansible_host=<node-ip>
```

In the same file, configure cluster node configuration (`master`,`etcd`,`worker`):

```ini
######
# KUBERNETES
######
[kube-master]
n0k0m3-master

# Odd number of nodes required
[etcd]
n0k0m3-master

[kube-node]
n0k0m3-master
n0k0m3-node01

[k8s-cluster:children]
kube-master
kube-node
```

Note: here we're using the master node as both the master and worker node. `etcd` and `master`/control-plane node are usually the same.

### Configure storage

By default, `deepops` setups an NFS server on the first `kube-master` node with export path `/export/deepops_nfs` for `nfs-client-provisioner` StorageClass. We will use this as a temporary storage for the cluster. Next part of this tutorial will offer a better solution for storage.

### Other DeepOps configurations

The patch already includes some of the currently used configurations for NETS lab. You can edit the configurations in `config/group_vars/all.yml` and `config/group_vars/k8s-cluster.yml` to suit your needs. Most of the configurations are self-explanatory. For more information, refer to the [DeepOps documentation](https://github.com/NVIDIA/deepops/blob/master/docs/k8s-cluster/README.md)


## Step 3: Deploy the cluster

Now we are ready to deploy the cluster. Run the following command to deploy the cluster:

```bash
cd ~/deepops
ansible all -m raw -a "hostname" # verify configuration
ansible-playbook -l k8s-cluster playbooks/k8s-cluster.yml
```

Verify GPU nodes are ready:

```bash
export CLUSTER_VERIFY_EXPECTED_PODS=2 # Expected number of GPUs in the cluster
./scripts/k8s/verify_gpu.sh
```

## Step 4: Configure `kubectl` locally

At this point, the cluster is ready to use. However, we need to configure `kubectl` locally to access the cluster. Copy `~/.kube/config` from the provision machine to the same path on your local machine (using `scp` or any file transfer software).

We will need to edit the `server` field in the `config` file to point to the master node's external IP address. Open the `config` file and edit the `server` field in the `cluster` section:
  
```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <CA-CERT>
    server: https://<KUBEAPI-SERVER-EXTERNAL-IP>:6443
  name: cluster.local
contexts:
```  

If we try to run `kubectl get nodes` now, we will get an error:

```bash
$ kubectl get nodes
E0509 21:08:29.820093    8619 memcache.go:265] couldn't get current server API group list: Get "https://<external-ip>:6443/api?timeout=32s": tls: failed to verify certificate: x509: certificate is valid for <kube-local-ip>, <node-local-ip>, 127.0.0.1, not <external-ip>
...
Unable to connect to the server: tls: failed to verify certificate: x509: certificate is valid for <kube-local-ip>, <node-local-ip>, 127.0.0.1, not <external-ip>
```

This is because the external IP address of the master node is not included in the `kubeadm` certificate. To fix this, we need to add the IP to `kubeadm-config`:

```bash
sudo nano /etc/kubernetes/kubeadm-config.yaml
```

```yaml
...
  extraVolumes:
  - name: usr-share-ca-certificates
    hostPath: /usr/share/ca-certificates
    mountPath: /usr/share/ca-certificates
    readOnly: true
  certSANs:
  - kubernetes
  - kubernetes.default
  - kubernetes.default.svc
  - kubernetes.default.svc.cluster.local
  - <kube-local-ip>
  - localhost
  - 127.0.0.1
  - n0k0m3-master
  - lb-apiserver.kubernetes.local
  - <node-local-ip>
  - <external-ip> # we add our external IP here
  timeoutForControlPlane: 5m0s
controllerManager:
  extraArgs:
    node-monitor-grace-period: 40s
...
```

Remove existing certificates for `kube-apiserver` and re-generate them:

```bash
sudo rm /etc/kubernetes/pki/apiserver.{crt,key}
sudo kubeadm init phase certs apiserver --config /etc/kubernetes/kubeadm-config.yaml
```

We will also need to kill existing `kube-apiserver` pods to force them to restart:

```bash
kubectl -n kube-system get pods -l component=kube-apiserver -o name | cut -d'/' -f2 | xargs -I{} kubectl -n kube-system delete pod {}
```

Now we should be able to access the cluster from our local machine:

```bash
$ kubectl get nodes
NAME            STATUS   ROLES           AGE   VERSION
n0k0m3-master   Ready    control-plane   41m   v1.25.6
n0k0m3-node01   Ready    <none>          40m   v1.25.6
```

# Conclusion

We have successfully deployed a Kubernetes cluster on the NETS lab. In the next part of this tutorial, we will deploy a StorageClass using `piraeus-operator` to provide persistent storage for the cluster.
