---
excerpt_separator: "<!--more-->"
categories:
  - Personal Projects
tags:
  - Linux
  - GPU
  - Docker
  - Tensorflow
title: Tensorflow with GPU support in Docker
date: 2021-05-02
last_modified_at: 2022-04-24
---

Following guide was tested on EndeavourOS and Manjaro (Arch-based) Linux distro.

## Why?

Installing dependencies and setting up notebooks is usually a PITA: installing CUDA with CuDNN and TensorRT doesn't have a common and easy to follow guide, along with recent (not recent) release of python 3.9, most ML/DL packages are not updated to this wheel. Also setting up `venv` is hard to maintain and migrate as you have to backup the whole environment to other machine.

`tensorflow/tensorflow` docker container solves this problem by allowing user to backup personalized config, while don't have to deal with maintaining the environment.

## Requirements

Nvidia driver is installed (using `nvidia-installer-dkms` from EndeavourOS or from Arch repo, on Manjaro use their hardware configurator, for other distro DIY). Note: `nouveau` (default open-source NVIDIA driver) is not supported

## Install docker

**Arch**: [(Arch Wiki guide)](https://wiki.archlinux.org/index.php/docker#Run_GPU_accelerated_Docker_containers_with_NVIDIA_GPUs)

Install `docker`
```sh
sudo pacman -S docker
```

Enable and start the service
```sh
sudo systemctl enable --now docker.service
```
(OPTIONAL, WARNING: insecure) Add your user to docker group in order to use docker command without `sudo`
```sh
sudo groupadd docker
sudo usermod -aG docker $USER
```
## Install nvidia-container toolkit for GPU access
Install `nvidia-container-toolkit`(AUR)
```sh
yay nvidia-container-toolkit
```
Restart `docker` service
```sh
sudo systemctl restart docker
```
Check if GPU is available inside docker
```sh
docker run --gpus all nvidia/cuda:11.3.0-runtime-ubuntu20.04 nvidia-smi
```

### Remap user

This will remap **ALL** users in docker to the current host-non-root (sudoer) user.

Find userid and groupid for your user:
```sh
id
#example output: uid=1000(n0k0m3) gid=1001(n0k0m3) groups=1001(n0k0m3)
```

We'll use `username=n0k0m3`, `uid=1000` and `gid=1001` from here (default username and usergroup)
```sh
sudo nano /etc/docker/daemon.json
```
Add this `json` to the file
```json
{
  "userns-remap": "1000:1001"
}
```
Update `subuid/gid`:
```sh
# Append sub-id to these files
sudo touch /etc/subuid
sudo touch /etc/subgid
echo "n0k0m3:1000:65536" | sudo tee -a /etc/subuid
echo "n0k0m3:1001:65536" | sudo tee -a /etc/subgid
```

Finally restart `docker` daemon:
```sh
sudo systemctl restart docker.service
```

## Run jupyter-tensorflow with port 6006 exposed for Tensorboard
Change directory to path containing jupyter folder, then run:
```sh
export JUPYTER_PATH=$(realpath jupyter)

docker run -d --gpus all \
    --name tf \
    -p 6006:6006 \
    -p 8888:8888 \
    -v $JUPYTER_PATH:/tf/notebooks \
    -v $JUPYTER_PATH/.jupyter:/root/.jupyter \
    -v $JUPYTER_PATH/.kaggle:/root/.kaggle \
    tensorflow/tensorflow:latest-gpu-jupyter
```
You can change the build tag `latest-gpu-jupyter` to any other support build tag on [DockerHub](https://hub.docker.com/r/tensorflow/tensorflow/tags). However I'd suggest sticking with `latest-gpu-jupyter` or `nightly-gpu-jupyter`

Next time to start the container:
```sh
docker start tf
```

<!-- ## Run jupyter datascience notebook from jupyter docker stack
Change directory to path containing jupyter folder, then run:
```sh
export JUPYTER_PATH=$(realpath jupyter)

docker run -d \
    --name ds \
    -p 6006:6006 \
    -p 8888:8888 \
    -v $JUPYTER_PATH:/home/jovyan/ \
    -e JUPYTER_ENABLE_LAB=yes \
    -e GRANT_SUDO=yes \
    -e RESTARTABLE=yes \
    jupyter/tensorflow-notebook
```

Next time to start the container:
```sh
docker start ds
```
 -->
### Common exposed ports setups

- `tensorflow/tensorflow:latest-gpu-jupyter` as `tf` for DL/AI training tasks
    - 6006 - Tensorboard
    - 8888 - JupyterLab notebook
- `n0k0m3/pyspark-notebook-deltalake-docker` as `ds` for PySpark + Deltalake support on `jupyter/pyspark-notebook`
    - 8888 - JupyterLab notebook
- `rapidsai/rapidsai:21.10-cuda11.4-runtime-ubuntu20.04-py3.8` as `ra` for GPU accelerated DataFrame
    - 8888 - JupyterLab notebook
    - 8786 - Dask scheduler
    - 8787 - Dask diagnostic web server

## TODO

- [ ] `docker-compose` that pull image from hub, name container, exposes ports, and mount volumes paths

## Problem with Docker and BTRFS (copied from [here](https://github.com/egara/arch-btrfs-installation/blob/master/README.md)) ##
More than a problem is a caveat. If the main filesystem for root is BTRFS, docker will use BTRFS storage driver (Docker selects the storage driver automatically depending on the system's configuration when it is installed) to create and manage all the docker images, layers and volumes. It is ok, but there is a problem with snapshots. Because **/var/lib/docker** is created to store all this stuff in a BTRFS subvolume which is into root subvolume, all this data won't be included within the snapshots. In order to allow all this data be part of the snapshots, we can change the storage driver used by Docker. The preferred one is **overlay2** right now. Please, check out [this reference](https://docs.docker.com/engine/userguide/storagedriver/selectadriver/) in order to select the proper storage driver for you. You must know that depending on the filesystem you have for root, some of the storage drivers will not be allowed.

For using overlay2:

- Create a file called **storage-driver.conf** within **/etc/systemd/system/docker.service.d/**. If the directory doens't exist, create the directory first.

```sh
sudo mkdir -p /etc/systemd/system/docker.service.d/
sudo nano /etc/systemd/system/docker.service.d/storage-driver.conf
```

- This is the content of **storage-driver.conf**

```sh
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// --storage-driver=overlay2
```

- Create **/var/lib/docker/** and disable CoW (copy on write for BTRFS):

```sh
sudo chattr +C /var/lib/docker
```

- Restart docker

```
sudo systemctl restart docker.service
```
