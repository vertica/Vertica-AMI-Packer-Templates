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


echo
echo "*** Remove unwanted packages"
echo 
# VER-46146
yum --color=never erase -y microcode_ctl

echo 
echo "*** Upgrade some software"
echo
#yum --color=never update -y glibc   # commenting this out for RH/CO 7.3 update
yum --color=never update -y cloud-init

echo 
echo "*** Install software"
echo
yum --color=never install -y wget mdadm vim screen perl-Time-HiRes nc sysstat mcelog gdb compat-libgfortran-41 yum-versionlock fuse fuse-libs curl-devel libxml2-devel openssl-devel mailcap s3cmd dialog python-pip unzip zip libgfortran

echo 
echo "*** Update kernel for patched security vulnerability"
echo
# Jiras:  VER-59802, VER-59803
# CVEs:  https://access.redhat.com/errata/RHSA-2018:0007
yum versionlock del kernel
yum --color=never update -y kernel kernel-tools-libs
yum versionlock kernel-3.10.0-693.11.6*

