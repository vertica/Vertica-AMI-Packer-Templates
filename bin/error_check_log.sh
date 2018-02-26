#!/bin/bash -e 

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

LOG_FILE=""
SCRIPT=`basename $0`
ARGS=$(getopt -o l:h -n ${SCRIPT}  -- "$@");


function usage {
    echo "usage: $0 -l <logfile>" 
    echo "options:"
    echo "-l <logfile>              name of packer log file to be parsed"
    echo "-h                        This message."
    exit 1
}

function handle_options {

    if [ $? -ne 0 ]; then
        usage
        exit 1
    fi

    eval set -- "$ARGS";

    while true; do
      case "$1" in
        -h)
            usage;
            exit;;
        -l)
            shift;
            LOG_FILE="$1";
            shift;;
        --)
            shift;
            break;;
       esac
    done
}

# --------------------- Main

handle_options

grep "AMIs were created" ${LOG_FILE} > /dev/null
#RC=$?

#grep -e 'Build .*amazon-ebs.* errored: Script exited with non-zero exit status' ${LOG_FILE} > /dev/null
#RC2=$?

#if [ $RC -ne 0 ] || [ $RC2 -eq 0 ] ; then
#    echo "${SCRIPT}: ERROR:  errors detected in build.  No AMI created"
#    echo "     AMI test: $RC, amazon-ebs test: $RC2"
#    exit 1
#fi

