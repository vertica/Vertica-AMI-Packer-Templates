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

sudo yum install perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https perl-Digest-SHA -y

sudo curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O

sudo unzip CloudWatchMonitoringScripts-1.2.1.zip

sudo rm CloudWatchMonitoringScripts-1.2.1.zip

sudo cd aws-scripts-mon

echo "*/5 * * * * ${PWD}/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/vertica/data --swap-util --from-cron" | sudo tee -a /var/spool/cron/${OS_USERNAME}


