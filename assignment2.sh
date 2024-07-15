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
    cp /etc/hosts /etc/hosts.bak 2>/dev/null
    echo 'File /etc/hosts was Successfully backed up'
fi

echo '---------------------------------------------'
echo 'Updating the /etc/hosts file: '
# Check if both hostname and IP address are already present in /etc/hosts
if grep -q "$NewIP $HostName" /etc/hosts; then
    echo 'Server1 IP & Host Name has already been updated'
else 
    if grep -q "$HostName" /etc/hosts; then
    	echo "Updating the IP address for $HostName in the /etc/hosts file"
    sed -i "s/^.*\s\+$HostName\$/$NewIP\t$HostName/" /etc/hosts
        echo "Host file was updated!"
    else
        echo "$NewIP $HostName" >> /etc/hosts
        echo "Added IP $NewIP and Host Name $HostName to /etc/hosts"
    fi
fi

echo '---------------------------------------------'
echo 'Software check:'

for PKG in apache2 squid; do
    if dpkg -l | grep -q "^ii  $PKG "; then
        echo "$PKG has already been installed"
    else
        echo "Installing $PKG..."
        apt-get update -qq > /dev/null 2>&1
        if apt-get install -y -qq "$PKG" > /dev/null 2>&1; then
        echo "$PKG was installed successfully"
    else
        echo "Error installing $PKG"
    fi
    fi
done


echo '---------------------------------------------'
echo 'Configuring the Firewall: '

if ! command -v ufw &> /dev/null; then
echo 'ufw not installed.. Installing ufw...'
	apt-get update > /dev/null 2>&1
	apt-get install ufw > /dev/null 2>&1
else 
	echo 'ufw was already installed'
fi

echo 'Enabling UFW...'
ufw --force enable > /dev/null 2>&1
if ufw status | grep -q "active"; then
	echo 'UFW is now active'
else
	echo 'UFW activation failed'
fi

if ufw status | grep -q "22.*ALLOW.*172.16.1.200/24"; then
	echo 'ufw has already been allowed on port 22'
else
	echo 'Allowing ufw to port 22 on mgmt...'
	ufw allow from 172.16.1.200/24 to any port 22 > /dev/null 2>&1
	if [ $? -eq 0 ]; then
	echo 'ufw on mgmt has been configured' 
else
	echo 'ufw configuration failed'
   fi
fi
   
if ufw status | grep -q "{80}/tcp.*ALLOW"; then
	echo 'UFW rule was already added'
else
	echo 'Adding UFW rule...'
	ufw allow 80/tcp > /dev/null 2>&1
	if ufw status | grep -q "{80}/tcp.*ALLOW"; then
	echo 'Rule was successfully added'
else 
	echo 'UFW rule failed to update'
   fi
fi
   
if ufw status | grep -q "{3128}/tcp.*ALLOW"; then
	echo 'UFW rule was already added'
else
	echo 'Adding UFW rule...'
	ufw allow 3128/tcp > /dev/null 2>&1
	if ufw status | grep -q "{3128}/tcp.*ALLOW"; then
	echo 'Rule was successfully added'
else
	echo 'UFW rule failed to update'
   fi
fi
echo '---------------------------------------------'
echo 'Creating User accounts: '

echo '---------------------------------------------'
echo 'Configuration complete!'
