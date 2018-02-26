#!/bin/sh -ex

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

groupadd -g 500 verticadba
sed -i "s/GROUP=100/GROUP=500/g" /etc/default/useradd
sed -i "s/USERGROUPS_ENAB yes/USERGROUPS_ENAB no/g" /etc/login.defs
sed -i "/^Defaults\s*requiretty/d" /etc/sudoers
sed -i "s/name: ${OS_USERNAME}/name: dbadmin/g;s/groups: \[wheel, adm, systemd-journal\]/groups: \[verticadba, wheel, adm, systemd-journal\]/g" /etc/cloud/cloud.cfg


