#!/bin/bash
# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file

# Default verbose flag
VERBOSE=false

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -verbose)
            VERBOSE=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Prepare verbose flag for remote scripts
if [ "$VERBOSE" = true ]; then
    VERBOSE_FLAG="-verbose"
else
    VERBOSE_FLAG=""
fi

# Run the configure-host.sh script on remote servers
scp configure-host.sh remoteadmin@server1-mgmt:/root
ssh remoteadmin@server1-mgmt -- /root/configure-host.sh $VERBOSE_FLAG -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4

scp configure-host.sh remoteadmin@server2-mgmt:/root
ssh remoteadmin@server2-mgmt -- /root/configure-host.sh $VERBOSE_FLAG -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3

# Run the configure-host.sh script locally
./configure-host.sh $VERBOSE_FLAG -hostentry loghost 192.168.16.3
./configure-host.sh $VERBOSE_FLAG -hostentry webhost 192.168.16.4

