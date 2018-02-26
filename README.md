This repository contains the packer template for creating the Vertica Server AMI.
# Notice
(c) Copyright 2017-2018 EntIT Software LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use the software in this repository except in 
compliance with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

# Overview
This repository contains a set of packer templates and provisioning scripts which are used to create a Vertica server AMI for a manually created base AMI.  The base AMI is a machine image with a filesystem paritioned for use with Vertica.   These templates support AMIs based upon Red Hat Enterprise Linux 7.4, CentOS 7.4, and Amazon Linux 2.0 RC candidate.  The templates also use the us-east-1 region.  This can be changed by editting the ```server_ami.json``` file.

Instructions for creating the base AMI are described below.

# Limitations

   * These templates work with Packer version 1.0.0.   Later versions of Packer introduce changes to the variable names and will not work with these templates.
   * These templates are tailored for use with Vertica version 9.0.0 and later.

# Preliminaries

1.  Install [Packer](www.packer.io) on your host.  These templates work with Packer version 1.0.0.   Later versions of Packer have changed some variable names.
2.  Create a ```aws_credentials.json``` file from the example, substituing your own AWS credentials.
3.  Create Base1 AMI (see below.)   

# Using Packer to Create the Vertica AMI

1. Create a directory 'rpms.server' containing the Vertica server and R Lang rpms of your choice.  
2. Run ``` bin/create_server_ami.sh -o <OS>```.   This script optinally takes one of two parameters:  -b \<build number\> or -n \<AMI name\>

# Creating the Base AMI

Red Hat/CentOS 7.4 and Amazon Linux 2.0 all use XFS as the root filesystem.  Vertica, however, does not support placement of the database on an XFS filesystem.  Therefore an additional EBS volume must be created, attached, and formatted as an EXT4 filesystem for hosting the database.

In addition we make the following configuration changes:

   * Create an 8GB swapfile
   * Lock the OS version so that it cannot be upgraded to a later (possibly unsupported) point release.
   * Configure Enhanced Networking interfaces in the AMI.  See the AWS [Enhanced Networking on Linux](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/enhanced-networking.html) for more information. Note that Amazon Linux 2.0 already has these interfaces enabled so this step may be skipped.

## Configuring the Base Instance
------------------------------------------

###  Instance Launch Parameters

Take the default options except for the values below:

* **Step 2:  Choose and Instance Type**
   * Instance Type: t2.small
* **Step 3:  Configure Instance Details**
   * VPC:                    vpc-37119c5f
   * Subnet:                 subnet-739eb31b
   * Auto-assign Public IP:  Enable 
* **Step 4:  Add Storage**
   * Root disk modified as follows:
        * Size (GB): 30
        * Type:  General Purpose SSD         
        * Check 'Delete on Termination'
   * Click 'Add New Volume'
        * Type:  EBS
        * Device:  /dev/sdb
        * Size: 20
        * Type:  General Purpose SDD
        * Check 'Delete on Termination'
* **Step 6:  Configure Security Group**
   * Security Group: sg-cc8f9a0

Now launch the instance
### Lock the OS point release
This prevents customers from yum-upgrading to a newer and possibly unsupported point release.
   * sudo yum install yum-plugin-versionlock
   
If building a CentOS-based AMI:

   * sudo yum versionlock add centos-release

If building a Red Hat Enterprise Linux AMI:
   
   * sudo yum versionlock add redhat-release-server

If building a Amazon Linux AMI:
   
   * sudo yum versionlock add system-release
   
### Create the swapfile on the root partition
```
dd if=/dev/zero of=/swapfile bs=1024 count=8290304
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile 
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
``` 

### Create New Partition on the Second Disk
   * fdisk /dev/xvdb
   * n
   * p 
   * \<return>
   * \<return>
   * \<return>
   * w 
   
Example:

```
[root@ip-10-0-10-170 ~]# fdisk /dev/xvdb

Welcome to fdisk (util-linux 2.23.2).

Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table
Building a new DOS disklabel with disk identifier 0x2d9a9a90.

Command (m for help): p

Disk /dev/xvdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x2d9a9a90

    Device Boot      Start         End      Blocks   Id  System

Command (m for help): n
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended
Select (default p): p
Partition number (1-4, default 1):
First sector (2048-41943039, default 2048):
Using default value 2048
Last sector, +sectors or +size{K,M,G} (2048-41943039, default 41943039):
Using default value 41943039
Partition 1 of type Linux and of size 20 GiB is set

Command (m for help): p

Disk /dev/xvdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x2d9a9a90

    Device Boot      Start         End      Blocks   Id  System
/dev/xvdb1            2048    41943039    20970496   83  Linux

Command (m for help): w
The partition table has been altered!

Calling ioctl() to re-read partition table.
Syncing disks.
```
   
### Create an EXT4 Filesystem on /vertica/data
```
mkfs -t ext4 /dev/xvdb1
mkdir -pv /vertica/data
echo "/dev/xvdb1 /vertica/data ext4 defaults,noatime 0 0" >> /etc/fstab
mount /vertica/data
```

## Add Enhanced Networking Interfaces (Red Hat and CentOS)
Two types of enhanced networking must be enabled manually on CentOS and Red Hat:  the Intel 82599 VF interface and the Elastic Network Adapter.   Amazon Linux has these interfaces already configured.

See:  http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/enhanced-networking.html

### Configuring the Intel 82599 VF Interface (ixgbevf)

```
sudo sed -i '/^GRUB\_CMDLINE\_LINUX/s/\"$/\ net\.ifnames\=0\"/' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

#### Set the SRIOV attribute on the instance

* Stop (not terminate!) the instance
* Set the attribute
```
aws ec2 modify-instance-attribute --instance-id <instance ID>  --sriov-net-support simple
```

You can verify ethe attribute setting by:
```
aws ec2 describe-image-attribute --image-id ami-11ece006 --attribute sriovNetSupport
```

### Configuring the Elastic Network Adapter (ena)
Begin to checking to see if an ENA module is already present (as it will be with Red Hat 7.4):
```
modinfo ena 
```

If so, unload the module and delete module file:
```
sudo rmmod ena
modinfo | grep filename
sudo rm -f \<filename from modinfo\>
```

The continue with downloading the updated ENA driver and installing it.
```
sudo yum install wget unzip gcc kernel-devel
wget https://github.com/amzn/amzn-drivers/archive/ena_linux_1.3.0.zip
unzip ena_linux_1.3.0.zip
cd amzn-drivers-ena_linux_1.3.0/kernel/linux/ena
make 
sudo mkdir -pv /lib/modules/$(uname -r)/kernel/drivers/ethernet/amazon/ena
sudo cp ena.ko /lib/modules/$(uname -r)/kernel/drivers/ethernet/amazon/ena/
sudo insmod /lib/modules/$(uname -r)/kernel/drivers/ethernet/amazon/ena/ena.ko
sudo vi /etc/modules-load.d/ena.conf
   ** Insert "ena" in the file
sudo depmod
```

Remove all the packages which you had to install with their dependencies.  (Except for the kernel, of course.)

```
sudo yum autoremove wget unzip gcc kernel-devel
```

Rebuild the initramfs

```
sudo cp /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bak_no_ena
sudo dracut -f
```

Lock YUM against kernel upgrades.  We must do this because the ENA kernel module for this specific kernel version.  Any later upgrade risks 
losing ENA support or rolling it back to an earlier version.

```
sudo yum versionlock add kernel
```

Stop the instance and set the ena-support attribute

```
aws ec2 modify-instance-attribute --instance-id instance_id --ena-support
```

## Finishing up

Save your instance as an AMI.   Update the ```config-ec2.json``` (for Red Hat), ```config-ec2-centos.json``` (for CentOS), or ```config-ec2-amzn.json``` (for Amazon Linux 2.0) with the base AMI id.

