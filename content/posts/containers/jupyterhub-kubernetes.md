---
excerpt_separator: "<!--more-->"
categories:
  - Containers
tags:
  - Kubernetes
  - k3s
  - Jupyter
  - JupyterHub
  - Helm
title: "Lightweight JupyterHub on k3s for Small Research Labs"
date: 2023-06-18
showtoc: true
---

Deploy JupyterHub on a lightweight k3s Kubernetes cluster for small research labs and teams, without the overhead of full Kubernetes installations.

<!--more-->

## Why k3s for JupyterHub?

**k3s** is a lightweight Kubernetes distribution perfect for:
- Small research labs with 2-5 nodes
- Resource-constrained environments
- Quick setup without complex infrastructure
- Built-in load balancer (Klipper) and storage provisioner

**Comparison with other solutions:**
- **vs. TLJH (The Littlest JupyterHub):** k3s offers better scalability and Kubernetes ecosystem
- **vs. full Kubernetes (DeepOps/kubeadm):** Simpler setup, lower resource overhead
- **vs. microk8s:** k3s has better multi-node support and lighter footprint

For enterprise-scale deployments with NVIDIA GPUs, see my [JupyterHub on Baremetal Kubernetes guide](../../NETS-deployment/nets-deployment-1/).

---

## Prerequisites

- 1+ Linux servers (Ubuntu 20.04+, Debian, RHEL, etc.)
- Minimum 2GB RAM per node
- SSH access to all nodes
- (Optional) Additional worker nodes for scaling

---

## Step 1: Setup k3s Cluster

### Install k3s Server (Master Node)

On your master/server node:

```bash
# Install k3s with write permissions for non-root kubectl access
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
```

**Get node token for workers:**
```bash
sudo cat /var/lib/rancher/k3s/server/node-token
```

**Get server IP:**
```bash
ip addr show  # or ifconfig
```

### Add Worker Nodes (Optional)

On each worker node:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<server_ip>:6443 K3S_TOKEN=<node-token> sh -
```

Replace:
- `<server_ip>`: IP address of your master node
- `<node-token>`: Token from previous step

### Verify Cluster

On the master node:

```bash
kubectl get nodes
```

Expected output:
```
NAME      STATUS   ROLES                  AGE   VERSION
master    Ready    control-plane,master   2m    v1.28.5+k3s1
worker1   Ready    <none>                 1m    v1.28.5+k3s1
```

---

## Step 2: Install Helm

Helm is the package manager for Kubernetes:

```bash
curl https://raw.githubusercontent.com/helm/helm/HEAD/scripts/get-helm-3 | bash
helm version
```

---

## Step 3: Configure Persistent Storage

k3s includes Local Path Provisioner by default. Verify it's available:

```bash
kubectl get storageclass
```

Expected output:
```
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer
```

### Optional: Install Faster Storage Provisioner

For better performance across nodes, install Local Path Provisioner explicitly:

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl get storageclass
```

---

## Step 4: Configure JupyterHub

Create `config.yaml` for JupyterHub customization:

```yaml
singleuser:
  memory:
    guarantee: 2G    # Minimum RAM per user
  cpu:
    guarantee: 1     # Minimum CPU cores per user
  storage:
    capacity: 10Gi   # Disk space per user

# Optional: Use specific image with pre-installed packages
#  image:
#    name: jupyter/scipy-notebook
#    tag: latest

# Optional: Enable GPU support (requires NVIDIA device plugin)
# singleuser:
#   extraResources:
#     limits:
#       nvidia.com/gpu: "1"
```

**Storage notes:**
- Default uses local-path storage class
- Each user gets an isolated persistent volume
- Adjust `capacity` based on your needs

**Resource notes:**
- `guarantee`: Resources reserved for each user
- Actual limits can be higher (set with `limits:` if needed)
- Start conservative and scale up based on usage

---

## Step 5: Install JupyterHub

```bash
# Add JupyterHub Helm repository
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update

# Define release name and namespace
RELEASE=jhub
NAMESPACE=jhub

# Check latest chart version: https://jupyterhub.github.io/helm-chart/
CHART_VERSION='3.2.1'

# Install JupyterHub
helm upgrade --cleanup-on-fail \
  --install $RELEASE jupyterhub/jupyterhub \
  --namespace $NAMESPACE \
  --create-namespace \
  --version=$CHART_VERSION \
  --values config.yaml
```

---

## Step 6: Monitor Installation

In a separate terminal, watch the installation progress:

```bash
# Watch pods starting
kubectl get pod --namespace jhub

# Watch services
kubectl get service --namespace jhub
```

**Wait for all pods to show `Running` status:**
```
NAME                              READY   STATUS    RESTARTS   AGE
continuous-image-puller-xxxxx     1/1     Running   0          2m
hub-xxxxxxxx-xxxxx                1/1     Running   0          2m
proxy-xxxxxxxx-xxxxx              1/1     Running   0          2m
```

---

## Step 7: Access JupyterHub

### Get the External IP

k3s includes Klipper load balancer which assigns an external IP:

```bash
kubectl get service --namespace jhub
```

Look for the `proxy-public` service:
```
NAME           TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)
proxy-public   LoadBalancer   10.43.xxx.xxx   192.168.1.100  80:xxxxx/TCP,443:xxxxx/TCP
```

### Access the Web Interface

Open your browser and navigate to:
```
http://<EXTERNAL-IP>
```

**Default authentication:**
- Any username/password combination works (dummy authenticator)
- **Production:** Configure real authentication (see customization section)

---

## Customization Examples

### Enable HTTPS with Let's Encrypt

Add to `config.yaml`:

```yaml
proxy:
  https:
    enabled: true
    hosts:
      - jupyter.yourdomain.com
    letsencrypt:
      contactEmail: your-email@example.com
```

### Configure GitHub OAuth

Add to `config.yaml`:

```yaml
hub:
  config:
    GitHubOAuthenticator:
      client_id: <your-github-oauth-client-id>
      client_secret: <your-github-oauth-client-secret>
      oauth_callback_url: https://jupyter.yourdomain.com/hub/oauth_callback
    JupyterHub:
      authenticator_class: github
```

[Create GitHub OAuth App](https://github.com/settings/developers)

### Add Custom Python Packages

Create custom Docker image or use `postBuild`:

```yaml
singleuser:
  profileList:
    - display_name: "Data Science Environment"
      description: "Python with common data science packages"
      kubespawner_override:
        image: jupyter/datascience-notebook:latest
    - display_name: "Minimal Environment"
      description: "Minimal Python environment"
      kubespawner_override:
        image: jupyter/minimal-notebook:latest
```

### Set Resource Limits

```yaml
singleuser:
  cpu:
    guarantee: 1
    limit: 2       # Maximum CPU cores
  memory:
    guarantee: 2G
    limit: 4G      # Maximum RAM
```

---

## Upgrading JupyterHub

After modifying `config.yaml`, upgrade the deployment:

```bash
helm upgrade --cleanup-on-fail \
  $RELEASE jupyterhub/jupyterhub \
  --namespace $NAMESPACE \
  --version=$CHART_VERSION \
  --values config.yaml
```

---

## Remote Access from Local Machine

### Option 1: Direct kubectl Access

Copy kubeconfig from server to local machine:

```bash
# On the server
cat /etc/rancher/k3s/k3s.yaml
```

On your local machine:
1. Copy content to `~/.kube/config`
2. Replace `server: https://127.0.0.1:6443` with `server: https://<server-ip>:6443`
3. Set context:
```bash
kubectl config set-context jhub-cluster
kubectl get nodes  # Verify connection
```

### Option 2: kubectl Port Forward (for testing)

```bash
kubectl port-forward -n jhub service/proxy-public 8080:80
```

Access at `http://localhost:8080`

---

## Troubleshooting

### Issue: Pods stuck in `Pending` state

**Check events:**
```bash
kubectl describe pod -n jhub <pod-name>
```

**Common causes:**
- Insufficient resources: Check `kubectl top nodes`
- Storage issues: Verify `kubectl get pvc -n jhub`
- Image pull errors: Check `docker pull <image-name>` on nodes

### Issue: Can't access JupyterHub web interface

**Check service:**
```bash
kubectl get service -n jhub proxy-public
```

**Verify firewall:**
```bash
# On server
sudo ufw allow 6443/tcp  # k3s API
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
```

### Issue: User pods failing to start

**Check logs:**
```bash
kubectl logs -n jhub hub-xxxxxxxx-xxxxx
```

**Common issues:**
- Storage class not available
- Resource limits too restrictive
- Image pull failures

---

## Maintenance Commands

```bash
# Check cluster status
kubectl get nodes
kubectl get pods -n jhub

# View JupyterHub logs
kubectl logs -n jhub deployment/hub

# Restart JupyterHub hub
kubectl rollout restart deployment/hub -n jhub

# Check resource usage
kubectl top nodes
kubectl top pods -n jhub

# List active users
kubectl get pods -n jhub -l component=singleuser-server
```

---

## Cleanup

### Remove JupyterHub

```bash
helm delete $RELEASE --namespace $NAMESPACE
kubectl delete namespace $NAMESPACE
```

### Uninstall k3s

**On server:**
```bash
/usr/local/bin/k3s-uninstall.sh
```

**On workers:**
```bash
/usr/local/bin/k3s-agent-uninstall.sh
```

---

## Next Steps

- **Add GPU support:** Install NVIDIA device plugin for GPU-accelerated notebooks
- **Setup monitoring:** Deploy Prometheus + Grafana for cluster monitoring
- **Configure backups:** Setup automated backups of user data
- **Add shared datasets:** Mount NFS shares for common datasets
- **Enable collaboration:** Install JupyterLab extensions for real-time collaboration

---

## Comparison with Enterprise Setup

| Feature | k3s (this guide) | DeepOps/full K8s |
|---------|------------------|------------------|
| Setup time | 15 minutes | 2-4 hours |
| Resource overhead | ~500MB RAM | ~2GB RAM |
| GPU support | Manual setup | Built-in |
| Storage | Local path | Ceph/NFS/custom |
| Scale | 2-10 nodes | 10-1000+ nodes |
| Best for | Small teams | Enterprise labs |

For enterprise deployments with NVIDIA GPUs and advanced storage, see my [full Kubernetes guide](../../NETS-deployment/nets-deployment-1/).

---

## References

- [k3s Documentation](https://docs.k3s.io/)
- [Zero to JupyterHub with Kubernetes](https://zero-to-jupyterhub.readthedocs.io/)
- [k3s vs microk8s comparison](https://medium.com/@cristianduguet/jupyterhub-bare-metal-vs-kubernetes-tljh-vs-z2jh-a5f03f0225a9)

---

**Created:** 2025-12-02
**Tested On:** Ubuntu 22.04, k3s v1.28+, JupyterHub Helm Chart v3.2+
