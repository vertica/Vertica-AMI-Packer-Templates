#!/bin/bash 

# Create Vertica AMI
# Usage:  create_ami.sh <build_designator>

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

RUN_CONFIG=run-config.json
BUILD_NUMBER=""
SCRIPT=`basename $0`
ARGS=$(getopt -o o:b:n:l:v:hR -n ${SCRIPT}  -- "$@");


function usage {
    echo "usage: $0 -o [RHEL|CENTOS|AMZN] [-b <build_number>] [-n <ami_name>] [-v <vertica version>] [-R]" 
    echo "options:"
    echo "-o <os>                   Base operating system.  [RHEL|CENTOS|AMZN]"
    echo "-b <build_number>         [optional] A meaningful build designator. Ex: build number, RC, GA, etc."
    echo "-n <ami name>             [optional] A meaningful AMI name."
    echo "-v <vertica version>      [optional] Vertica version number (overrides config-ec2.json value)"
    echo "-l <logfile name>         [optional] Name of the file to log packer stdout"
    echo "-R                        [optional] Don't generate a run-config.json file"
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
        -o)
            shift;
            OS="$1";
            shift;;
        -b)
            shift;
            BUILD_NUMBER="$1";
            shift;;
        -n)
            shift;
            USERS_AMI_NAME="$1";
            shift;;
        -v)
            shift;
            VERTICA_VERSION="$1";
            shift;;
        -l)
            shift;
            LOGFILE="$1";
            shift;;
        -R)
            SKIP_RUN_CONFIG="true";
            shift;;
        --)
            shift;
            break;;
       esac
    done
}

# --------------------- Main

handle_options

PACKER_FILE=server_ami.json

if [ "${OS}" = "RHEL" ]; then
    RPM_OS="RHEL6"
    PACKER_LOG=packer_redhat.$$.log
    EC2_CONFIG="config-ec2.json"
elif [ "${OS}" = "CENTOS" ]; then
    RPM_OS="RHEL6"
    PACKER_LOG=packer_centos.$$.log
    EC2_CONFIG="config-ec2-centos.json"
elif [ "${OS}" = "AMZN" ]; then
    RPM_OS="RHEL6"
    PACKER_LOG=packer_amzn.$$.log
    EC2_CONFIG="config-ec2-amzn.json"
else
    echo "ERROR: OS ${OS} not supported"
    exit 1
fi

if [ -n "$LOGFILE" ]; then
    PACKER_LOG=$LOGFILE
fi

if [ "x${USERS_AMI_NAME}" = "x" ]; then
    # Calculate default value of AMI_NAME.  Can be overridden from command line"
    #
    RPM_VERSION=`rpm -qp --qf '%{VERSION}' rpms.server/vertica-x86_64.${RPM_OS}.latest.rpm`
    RPM_RELEASE=`rpm -qp --qf '%{RELEASE}' rpms.server/vertica-x86_64.${RPM_OS}.latest.rpm`
    AMI_NAME="Daily ${RPM_VERSION}-${RPM_RELEASE}"
else
    AMI_NAME="${USERS_AMI_NAME}"
fi

# build run configuration file
#
if [ -z "${SKIP_RUN_CONFIG}" ]; then 
    rm -rf ${RUN_CONFIG}
    echo "{" > ${RUN_CONFIG}

    # Add build type if specified
    if [ ! -z "${BUILD_NUMBER}" ]; then
        echo -n " \"build_number\": \"" >> ${RUN_CONFIG}
        echo -n "${BUILD_NUMBER}" >> ${RUN_CONFIG}
        echo "\"," >> ${RUN_CONFIG}
    fi

    # Add vertica version if specified
    if [ ! -z "${VERTICA_VERSION}" ]; then
        echo -n " \"vertica_version\": \"" >> ${RUN_CONFIG}
        echo -n "${VERTICA_VERSION}" >> ${RUN_CONFIG}
        echo "\"," >> ${RUN_CONFIG}
    fi

    # Add AMI name
    echo -n " \"ami_name\": \"" >> ${RUN_CONFIG}
    echo -n "${AMI_NAME}" >> ${RUN_CONFIG}
    echo "\"" >> ${RUN_CONFIG}

    echo "}" >> ${RUN_CONFIG}
fi

echo "Packer version: `packer version`"
echo "Location: `which packer`"
echo "Host: `hostname`"
echo "Software revision:  `git rev-parse HEAD`"
cat ${RUN_CONFIG}

PACKER_OPERATION="build --color=false"
#PACKER_OPERATION="validate"
PACKER_COMMAND="packer ${PACKER_OPERATION} -var-file=${EC2_CONFIG} -var-file=config-ec2-vpc.json -var-file=aws_credentials.json -var-file ${RUN_CONFIG} ${PACKER_FILE}"

# Export this for packer debugging
#export PACKER_LOG=debug.log

echo "Packer command:  ${PACKER_COMMAND}"

${PACKER_COMMAND} 2>&1 | tee ${PACKER_LOG} 


