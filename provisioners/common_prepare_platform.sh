#!/bin/sh -ex

# Copyright 2017-2018 EntIT Software LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

OS=`grep ^ID= /etc/os-release | cut -f2 -d= | sed 's/\"//g'`

echo "Setting SELINUX to permissive"
sed -i "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config

echo "Updating network settings -- sysctl.conf"
cat fragment.sysctl.conf >> /etc/sysctl.conf
rm fragment.sysctl.conf

echo "Update rc.local"
cat fragment.rc.local.platform >> fragment.rc.local
echo "touch /var/lock/subsys/local" >> fragment.rc.local
mv -v fragment.rc.local /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

echo "Install MOTD"
mv -v motd /etc/motd

date
systemctl start rc-local
ls -la /var/lock/subsys/local

case $OS in
    rhel|centos)
        echo "Disable tuned"
        systemctl stop tuned.service
        systemctl disable tuned.service
        ;;
esac

echo "Disable C-State and P-state for AMI (required for clean support of m4.10xlarge AMI)"
case $OS in
    rhel|centos)
        sed -i '/kernel/ s/$/ intel_idle.max_cstate=0/' /boot/grub/grub.conf
        ;;
    amzn)
        sed -i '/console=tty0/ s/$/ intel_idle.max_cstate=0/' /boot/grub2/grub.cfg
        ;;
    *)
        echo "ERROR: don't know how to turn of C State for OS $OS"
        exit 1
        ;;
esac



