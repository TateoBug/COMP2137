#!/bin/bash

#assigning the variables
HostName="server1"
NewIP="192.168.16.21"

#Prints out message to begin configuration script
echo 'Starting Configurations: '
echo '---------------------------------------------'
#Prints that the original file has either already been backed up or is going to be backed up
echo 'Backing up the original /etc/hosts file: '
if [ -f /etc/hosts.bak ]; then
    echo '/etc/hosts file was already backed up'
else
    cp /etc/hosts /etc/hosts.bak > /dev/null 2>&1
    echo 'File /etc/hosts was Successfully backed up'
fi

echo '---------------------------------------------'
echo 'Updating the /etc/hosts file: '
# Check if both hostname and IP address are already present in /etc/hosts
if grep -q "$NewIP $HostName" /etc/hosts; then
    echo 'Server1 IP & Host Name has already been updated'
else 
    if grep -q "$HostName" /etc/hosts; then
        sed -i "s/^.*\s\+$HostName\$/$NewIP\t$HostName/" /etc/hosts
        echo "Updating the IP address for $HostName in the /etc/hosts file"
    else
        echo "$NewIP $HostName" >> /etc/hosts
        echo "Added IP $NewIP and Host Name $HostName to /etc/hosts"
    fi
fi


echo '---------------------------------------------'
echo 'Software check:'

install_package() {
    if dpkg -l | grep -q "^ii  $1 "; then
        echo "$1 has already been installed"
    else
        echo "Installing $1..."
        apt-get update -qq > /dev/null 2>&1
        if apt-get install -y -qq "$1" > /dev/null 2>&1; then
        echo "$1 was installed successfully"
    else
        echo "Error installing $1"
    fi
fi
}

install_package apache2
install_package squid

echo '---------------------------------------------'
echo 'Configuring the Firewall: '
#ufw allow from 172.16.1.200

#if ufw 
echo '---------------------------------------------'
echo 'Creating User accounts: '

echo '---------------------------------------------'
echo 'Configuration complete!'
