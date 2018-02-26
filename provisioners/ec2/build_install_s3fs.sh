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
echo "*** install s3fs build dependencies"
echo 
#yum --color=never install -y gcc libstdc++-devel gcc-c++ curl-devel libxml2-devel openssl-devel mailcap fuse fuse-devel fuse-libs automake wgetyum install -y gcc libstdc++-devel gcc-c++ curl-devel libxml2-devel openssl-devel mailcap fuse fuse-devel fuse-libs automake wget
yum --color=never install -y automake fuse fuse-devel gcc-c++ git libcurl-devel libxml2-devel make openssl-devel

echo
echo "*** build s3fs"
echo
wget  https://github.com/s3fs-fuse/s3fs-fuse/archive/v1.82.tar.gz
tar xzf v1.82.tar.gz
cd s3fs-fuse-1.82/
./autogen.sh
./configure --prefix=/usr
make
make install

echo
echo "*** clean up s3fs build dependencies"
echo
#yum --color=never remove -y autoconf automake cpp gcc glibc-devel glibc-headers kernel-headers keyutils-libs-devel krb5-devel libcom_err-devel libidn-devel libselinux-devel libsepol-devel zlib-devel  libstdc++-devel gcc-c++ curl-devel libxml2-devel openssl-devel  fuse-devel
yum --color=never remove -y automake fuse fuse-devel gcc-c++ git libcurl-devel libxml2-devel make openssl-devel
cd ..
rm -rf s3fs-fuse-1.82 v1.82.tar.gz

