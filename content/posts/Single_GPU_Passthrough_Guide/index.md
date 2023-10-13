---
excerpt_separator: "<!--more-->"
categories:
  - Personal Projects
tags:
  - Linux
  - GPU
  - VFIO
title: VFIO Single GPU Passthrough Guide on Linux
date: 2021-05-01
lastmod: 2022-04-25
showtoc: true
---

Why single GPU passthrough? Because I'm poor, using Ryzen non-APU CPU, and I don't want to buy a second GPU just for passthrough. I'm using a single GPU passthrough for gaming on Windows and using Linux as my daily driver. 

In this guide, we will be going over how to set up a single GPU passthrough on Linux. This guide is meant to be a reference for myself and others who want to learn how to set up a single GPU passthrough on Linux. I'm using Arch Linux as the host OS, but this guide should work on any Linux distro.

## 1. Notes



Most of these commands will be run under `root`.

```sh
sudo su -
```

## 2. Host Machine Settings

### 2.1 Enable & Verify IOMMU

#### 2.1.1 Enabling IOMMU in BIOS



Varies and depends on motherboard. Follow this guide: [Arch Wiki](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF#Enabling_IOMMU)

#### 2.1.2 Add kernel for IOMMU in GRUB



Add these flags to the end of `GRUB_CMDLINE_LINUX_DEFAULT` variable

| `nano /etc/default/grub`                                                         |
| -------------------------------------------------------------------------------- |
| For Intel CPU                                                                    |
| `GRUB_CMDLINE_LINUX_DEFAULT="... intel_iommu=on iommu=pt rd.driver.pre=vfio-pc"` |
| For AMD CPU                                                                      |
| `GRUB_CMDLINE_LINUX_DEFAULT="... amd_iommu=on iommu=pt rd.driver.pre=vfio-pc"`   |

Generate grub.cfg

```sh
grub-mkconfig -o /boot/grub/grub.cfg
```

Reboot your system for the changes to take effect.

#### 2.1.3 Checking IOMMU



By this point IOMMU should be enabled. Check if there's a return

```sh
sudo dmesg | grep 'IOMMU'
```

Example return

```
[    0.731687] pci 0000:00:00.2: AMD-Vi: IOMMU performance counters supported
[    0.732465] pci 0000:00:00.2: AMD-Vi: Found IOMMU cap 0x40
[    0.732730] perf/amd_iommu: Detected AMD IOMMU #0 (2 banks, 4 counters/bank).
[    0.747591] AMD-Vi: AMD IOMMUv2 driver by Joerg Roedel <jroedel@suse.de>
```

#### 2.1.4 IOMMU group

IOMMU is the SMALLEST group that you can passthrough to VM, means that ALL devices in IOMMU must be **passthrough** to the VM

Run this command to check IOMMU grouping:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/n0k0m3/Personal-Setup/main/GPU_Passthrough/iommu.sh)" >> iommu.txt
## Delete ">> iommu.txt" to see output in stdout
```

Example output `iommu.txt`

```
...
IOMMU group 23
	09:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA104 [GeForce RTX 3060 Ti] [10de:2486] (rev a1)
[NORES]	09:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:228b] (rev a1)
...
```

Here our NVIDIA GPU is in group 23 and well isolated. Note the `[NORES]` flag means that the device won't power-cycle properly after VM shutdown ([Source](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_through_a_device_that_does_not_support_resetting)). For now remember device IDs `09:00.0`, `09:00.1` to passthrough

If your PCIe devices are not well-isolated, ~~check [ACS Override Kernel](https://queuecumber.gitlab.io/linux-acs-override/) and [ACS Patching Guide](https://github.com/bryansteiner/gpu-passthrough-tutorial#----acs-override-patch-optional). However, I wouldn't recommend this as it is really insecure ([source](https://www.reddit.com/r/VFIO/comments/bvif8d/official_reason_why_acs_override_patch_is_not_in/)). Better sell your motherboard and get one with better IOMMU grouping.~~  
Install `linux-zen` (available as binary) or any `linux-xanmod` (build from source) kernel (or any kernel that have ACS override patches) and add `pcie_acs_override=downstream,multifunction` to the boot options in `/etc/default/grub`. I don't need this for my system, but it's good to know.

### 2.2 Installing Packages



**Arch Linux**

```sh
pacman -S qemu libvirt edk2-ovmf virt-manager dnsmasq ebtables
```

<details>
  <summary><b>Fedora</b></summary>

```sh
dnf install @virtualization
```

</details>

<details>
  <summary><b>Ubuntu</b></summary>

```sh
apt install qemu-kvm qemu-utils libvirt-daemon-system libvirt-clients bridge-utils virt-manager ovmf
```

</details>

### 2.3 Enable required services



```sh
systemctl enable --now libvirtd
```

Sometimes, you might need to start default network manually.

```sh
virsh net-start default
virsh net-autostart default
```

## 3. Setup Virtual Machine

I already have a VM with Windows 10 installed, with SSD passthrough, backed up with all definitions in virsh xml file so I'll just import it.

```sh
virsh define <path-to-xml>/<vm-name>.xml
```

Following is the guide to create a VM similar to my setup.

### 3.1 Setting up VM and install Guest OS (Windows 10)



**_NOTE: You should replace win10 with your VM's name where applicable_** \
You should add your user to **_libvirt_** group to be able to run VM without root. And, **_input_** and **_kvm_** group for passing input devices.

```sh
usermod -aG kvm,input,libvirt $USER
```

- Download [virtio](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso) driver for windows.
- Launch **_virt-manager_** and create a new virtual machine. Select **_Customize before install_** on Final Step.
- In **_Overview_** section, set **_Chipset_** to **_Q35_**, and **_Firmware_** to **_UEFI_** using OVMF (Not tested with secboot so YMMV)
- In **_CPUs_** section, set **_CPU model_** to **_host-passthrough_**, and **_CPU Topology_** to whatever fits your system.
- For **_SATA_** disk of VM, set **_Disk Bus_** to **_virtio_**.
- In **_NIC_** section, set **_Device Model_** to **_virtio_**
- Add Hardware > CDROM: virtio-win.iso
- Now, **_Begin Installation_**. Windows can't detect the **_virtio disk_**, so you need to **_Load Driver_** and select **_virtio-iso/amd64/win10_** when prompted.
- After successful installation of Windows, install virtio drivers from virtio CDROM. You can then remove virtio iso.

### 3.2 Attaching PCI devices



**Keep `Display Spice` and `Video QXL` for debugging**  
Remove `Channel Spice`, `Sound ich*` and other unnecessary devices.  
Now, click on **_Add Hardware_**, select **_PCI Host Device_** and add the PCI Host devices for your GPU's VGA and HDMI Audio, in this example, `[09:00.0]` and `[09:00.1]`

#### 3.2.1 Video card driver virtualisation detection



Spoof Hyper-V Vendor ID for GPU guest drivers (AMD).

<div class="code-example" markdown="1">
`virsh edit win10`
</div>

```xml
...
<features>
  ...
  <hyperv>
    ...
    <vendor_id state='on' value='randomid'/>
    ...
  </hyperv>
  ...
</features>
...
```

NVIDIA guest drivers prior to version 465 require hiding the KVM CPU leaf (avoid error 43):

<div class="code-example" markdown="1">
`virsh edit win10`
</div>

```xml
...
<features>
  ...
  <kvm>
    <hidden state='on'/>
  </kvm>
  ...
</features>
...
```

### 3.3 Keyboard/Mouse/Audio Passthrough



I won't be using passthrough as the latency and complicated setup is not worth it. Follow [USB Controller Passthrough](#usb-controller-passthrough)

### 3.4 USB Controller Passthrough



Passing through Audio through PulseAudio is laggy, and passing Keyboard/Mouse/Audio is complicated. Also, you won't be able to use the main machine in Single GPU Passthrough setup anyway.

Run this script to print which USB devices on which PCIe USB controller:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/n0k0m3/Personal-Setup/main/GPU_Passthrough/usb_iommu.sh)" >> usb_iommu.txt
## Delete ">> usb_iommu.txt" to see output in stdout
```

Example output

```
...
Bus 5 --> 0000:0b:00.3 (IOMMU group 27)
Bus 005 Device 005: ID 04d9:0024 Holtek Semiconductor, Inc. USB Gaming Keyboard
Bus 005 Device 004: ID 046d:c53f Logitech, Inc. USB Receiver
Bus 005 Device 003: ID 0fce:51e0 Sony Ericsson Mobile Communications AB F5122 [Xperia X dual] (developer mode)
Bus 005 Device 002: ID 2109:2813 VIA Labs, Inc. VL813 Hub
Bus 005 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub

Bus 6 --> 0000:0b:00.3 (IOMMU group 27)
Bus 006 Device 003: ID 2109:0813 VIA Labs, Inc. VL813 Hub
Bus 006 Device 002: ID 1058:25fb Western Digital Technologies, Inc. easystore Desktop (WDBCKA)
Bus 006 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
...
```

Note here that we don't care about the bus but rather the PCIe hardware ID and IOMMU group. Let's go back and check the grouping

```
...
IOMMU group 27
	0b:00.3 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] Matisse USB 3.0 Host Controller [1022:149c]
...
```

In my setup the USB controller is isolated with the rest, which is perfect. Now I just need to pass this whole device (`0b:00.3`) to VM

To find which USB port belongs to which controller/IOMMU group, replug your mouse/keyboard/random USB to every port on PC and rerun the script. Usually adjacent USB ports are from same controller.

<details>
  <summary><b>Some outlier (click to reveal)</b></summary>

In my current setup Group 18 is also contains USB controller

```
...
IOMMU group 18
	03:08.0 PCI bridge [0604]: Advanced Micro Devices, Inc. [AMD] Matisse PCIe GPP Bridge [1022:57a4]
	06:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Starship/Matisse Reserved SPP [1022:1485]
[NORES]	06:00.1 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] Matisse USB 3.0 Host Controller [1022:149c]
	06:00.3 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] Matisse USB 3.0 Host Controller [1022:149c]
...
```

Corresponding USB bus

```
...
Bus 1 --> 0000:06:00.1 (IOMMU group 18)
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub

Bus 2 --> 0000:06:00.1 (IOMMU group 18)
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub

Bus 3 --> 0000:06:00.3 (IOMMU group 18)
Bus 003 Device 005: ID 0b05:18f3 ASUSTek Computer, Inc. AURA LED Controller
Bus 003 Device 003: ID 8087:0025 Intel Corp. Wireless-AC 9260 Bluetooth Adapter
Bus 003 Device 008: ID 04d9:0024 Holtek Semiconductor, Inc. USB Gaming Keyboard
Bus 003 Device 007: ID 0bda:4014 Realtek Semiconductor Corp. USB Audio
Bus 003 Device 006: ID 0fce:51e0 Sony Ericsson Mobile Communications AB F5122 [Xperia X dual] (developer mode)
Bus 003 Device 004: ID 046d:c53f Logitech, Inc. USB Receiver
Bus 003 Device 002: ID 0424:2137 Microchip Technology, Inc. (formerly SMSC) USB2137B
Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub

Bus 4 --> 0000:06:00.3 (IOMMU group 18)
Bus 004 Device 004: ID 1058:25fb Western Digital Technologies, Inc. easystore Desktop (WDBCKA)
Bus 004 Device 003: ID 0bda:8153 Realtek Semiconductor Corp. RTL8153 Gigabit Ethernet Adapter
Bus 004 Device 002: ID 0424:5537 Microchip Technology, Inc. (formerly SMSC) USB5537B
Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
...
```

Due to [reset problem](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_through_a_device_that_does_not_support_resetting), we need to figure out devices that can be power-cycled using linux. In group 18 one of our USB controller cannot be reset (`06:00.1`). Also LED controller, Wifi, etc. is bundled in this group, along with PCIe bridge, which is terrible to deal with and isolate. So we will not use this controller/controller group

</details>

## 4. Libvirt Hooks



Libvirt hooks automate the process of running specific tasks during VM state change. \
More info at: [PassthroughPost](https://passthroughpo.st/simple-per-vm-libvirt-hooks-with-the-vfio-tools-hook-helper/)

Copy `hooks` folder to `/etc/libvirt/`

```sh
cp -R hooks /etc/libvirt/
```

Edit `/etc/libvirt/hooks/kvm.conf` with regard to the output of `iommu.txt`

<!---
<details>
  <summary><b>Create Libvirt Hook</b></summary>

```sh
mkdir /etc/libvirt/hooks
touch /etc/libvirt/hooks/qemu
chmod +x /etc/libvirt/hooks/qemu
```

  <table>
  <tr>
  <th>
    /etc/libvirt/hooks/qemu
  </th>
  </tr>

  <tr>
  <td>

```sh
#!/bin/bash

GUEST_NAME="$1"
HOOK_NAME="$2"
STATE_NAME="$3"
MISC="${@:4}"

BASEDIR="$(dirname $0)"

HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"
set -e # If a script exits with an error, we should as well.

if [ -f "$HOOKPATH" ]; then
eval \""$HOOKPATH"\" "$@"
elif [ -d "$HOOKPATH" ]; then
while read file; do
  eval \""$file"\" "$@"
done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
fi
```

  </td>
  </tr>
  </table>
</details>

<details>
  <summary><b>Create Start Script</b></summary>

```sh
mkdir -p /etc/libvirt/hooks/qemu.d/win10/prepare/begin
touch /etc/libvirt/hooks/qemu.d/win10/prepare/begin/start.sh
chmod +x /etc/libvirt/hooks/qemu.d/win10/prepare/begin/start.sh
```

  <table>
  <tr>
  <th>
    /etc/libvirt/hooks/qemu.d/win10/prepare/begin/start.sh
  </th>
  </tr>

  <tr>
  <td>

```sh
#!/bin/bash
set -x

# Stop display manager
systemctl stop display-manager
# rc-service xdm stop

# Unbind EFI Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Unload NVIDIA kernel modules
modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia

# Unload AMD kernel module
# modprobe -r amdgpu

# Detach GPU devices from host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-detach pci_0000_01_00_0
virsh nodedev-detach pci_0000_01_00_1

# Load vfio module
modprobe vfio-pci
```

  </td>
  </tr>
  </table>
</details>

<details>
  <summary><b>Create Stop Script</b></summary>

```sh
mkdir -p /etc/libvirt/hooks/qemu.d/win10/release/end
touch /etc/libvirt/hooks/qemu.d/win10/release/end/stop.sh
chmod +x /etc/libvirt/hooks/qemu.d/win10/release/end/stop.sh
```

  <table>
  <tr>
  <th>
    /etc/libvirt/hooks/qemu.d/win10/release/end/stop.sh
  </th>
  </tr>

  <tr>
  <td>

```sh
#!/bin/bash
set -x

# Unload vfio module
modprobe -r vfio-pci

# Attach GPU devices to host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-reattach pci_0000_01_00_0
virsh nodedev-reattach pci_0000_01_00_1

# Rebind framebuffer to host
echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

# Load NVIDIA kernel modules
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia

# Load AMD kernel module
# modprobe amdgpu

# Restart Display Manager
systemctl start display-manager
# rc-service xdm start
```

  </td>
  </tr>
  </table>
</details>
-->

## 5. vBIOS Patching (No need for my setup)



**_NOTE: vBIOS patching is not patching directly into the hardware. You only patch the dumped ROM file._** \
While most of the GPU can be passed with stock vBIOS, some GPU requires vBIOS patching depending on your host distro. \
In order to patch vBIOS, you need to first dump the GPU vBIOS from your system. \
If you have Windows installed, you can use [GPU-Z](https://www.techpowerup.com/gpuz) to dump vBIOS. \
To dump vBIOS on Linux, you can use following command (replace PCI id with yours): \
If it doesn't work on your distro, you can try using live cd.

```sh
echo 1 > /sys/bus/pci/devices/0000:01:00.0/rom
cat /sys/bus/pci/devices/0000:01:00.0/rom > path/to/dump/vbios.rom
echo 0 > /sys/bus/pci/devices/0000:01:00.0/rom
```

To patch vBIOS, you need to use Hex Editor (eg., [Okteta](https://utils.kde.org/projects/okteta)) and trim unnecessary header. \
For NVIDIA GPU, using hex editor, search string “VIDEO”, and remove everything before HEX value 55. \
For other GPU, I have no idea.

To use patched vBIOS, edit VM's configuration to include patched vBIOS inside **_hostdev_** block of VGA

<div class="code-example" markdown="1">
`virsh edit win10`
</div>
```xml
...
<hostdev mode='subsystem' type='pci' managed='yes'>
  <source>
    ...
  </source>
  <rom file='/home/me/patched.rom'/>
  ...
</hostdev>
...
```

## References & See Also

[VFIO Single GPU Passthrough Configuration by Karuri](https://gitlab.com/Karuri/vfio)  
[Single GPU Passthrough by joeknock90](https://github.com/joeknock90/Single-GPU-Passthrough)  
[Complete Single GPU Passthrough by QaidVoid](https://github.com/QaidVoid/Complete-Single-GPU-Passthrough) (format for this guide)  
[Arch Wiki PCI passthrough via OVMF](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF)