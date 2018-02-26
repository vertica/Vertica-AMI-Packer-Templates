#!/bin/sh -x

# Copyright 2017 EntIT Software LLC
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

OS_USERNAME="ec2-user"
if [ -f /etc/centos-release ]; then 
    OS_USERNAME="centos"
fi

yum --color=never clean all

# remove temporary files
rm -v fragment.*
rm -rvf *.rpm 

# clean logs
find /var/log -name "*.log" -delete

rm -rf /tmp

# Disable root login
sed -i  "s/nullok//g" /etc/pam.d/system-auth /etc/pam.d/password-auth-ac /etc/pam.d/password-auth /etc/pam.d/system-auth-ac
# disable root login
passwd -d root
passwd -l root
 
# Remove keys
shred -uv /etc/ssh/*_key /etc/ssh/*_key.pub
[ ! -e /root/.ssh/authorized_keys ] || shred -u /root/.ssh/authorized_keys
[ ! -e /home/${OS_USERNAME}/.ssh/authorized_keys ] || shred -u /home/${OS_USERNAME}/.ssh/authorized_keys

# Remove myself
rm -rf $0

# clean shell history
find /root -name ".*history" -exec shred -u {} \;
find /home/$1 -name ".*history" -exec shred -u {} \;
echo "Done with cleanup provisioner."
history -c

