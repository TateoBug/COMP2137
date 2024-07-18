#!/bin/bash

# Assigning the variables
HostName="server1"
NewIP="192.168.16.21"
NewNetplanIP="192.168.16.21/24"
User_Accounts=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
DENNIS_ADDITIONAL_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

# Prints out message to begin configuration script
echo 'Starting Configurations: '
echo '---------------------------------------------'
# Prints that the original file has either already been backed up or is going to be backed up
echo 'Backing up the original /etc/hosts file: '
if [ -f /etc/hosts.bak ]; then
    echo '/etc/hosts file was already backed up'
else
    cp /etc/hosts /etc/hosts.bak 2>/dev/null
    echo 'File /etc/hosts was Successfully backed up'
fi

echo '---------------------------------------------'
echo 'Updating netplan file: '

echo 'Checking netplan ip...'
if grep -q "$NewNetplanIP" /etc/netplan/10-lxc.yaml; then
    echo 'Netplan IP has been updated already'
else 
#search for what ever IP is in netplan eth0 addresses
    if grep -A 2 "eth0:" /etc/netplan/10-lxc.yaml | grep "addresses:"; then
        echo "Updating the IP address for netplan..."
        sed -i '/eth0:/,/^ *[^ ]/ { /addresses:/ s/addresses: .*/addresses: [ '"$NewNetplanIP"' ]/ }' /etc/netplan/10-lxc.yaml
        echo 'Netplan IP has been updated'
    else
        echo 'Netplan update has failed'
    fi
fi

netplan apply > /dev/null 2>&1
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

echo 'Checking for ufw...'
if ! command ufw &> /dev/null; then
    echo 'ufw not installed.. Installing ufw...'
    apt-get update > /dev/null 2>&1
    if apt-get install -y ufw > /dev/null 2>&1; then
    echo 'ufw successfully installed'
else 
    echo 'ufw install failed'
  fi
fi

echo 'Checking for ufw rules...'
if ufw status | grep -q "22.*ALLOW.*172.16.1.200/24"; then
    echo 'ufw has already been allowed to port 22'
else
    echo 'Allowing ufw to port 22 on mgmt...'
    ufw allow from 172.16.1.200/24 to any port 22 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo 'ufw on mgmt has been configured' 
    else
        echo 'ufw configuration failed'
    fi
fi
   
if ufw status | grep -q "80/tcp.*ALLOW"; then
    echo 'UFW rule was already added to port 80'
else
    echo 'Adding UFW rule to port 80...'
    ufw allow 80/tcp > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo 'Rule was successfully added to port 80'
    else 
        echo 'UFW rule failed to update'
    fi
fi
   
if ufw status | grep -q "3128/tcp.*ALLOW"; then
    echo 'UFW rule was already added to port 3128'
else
    echo 'Adding UFW rule to port 3128...'
    ufw allow 3128/tcp > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo 'Rule was successfully added to port 3128'
    else
        echo 'UFW rule failed to update'
    fi
fi

echo 'Enabling UFW...'
if ufw status | grep -q -w "active"; then
    echo 'UFW is already active'
else
    ufw --force enable > /dev/null 2>&1
    if ufw status | grep -q "inactive"; then
        echo 'UFW is now active'
    else
        echo 'UFW activation failed'
    fi
fi
echo 'Ufw reloading...'
ufw reload > /dev/null 2>&1
echo '---------------------------------------------'
echo 'User accounts: '

echo "Creating user $User..."
for User in "${User_Accounts[@]}"; do
    if id "$User" &>/dev/null; then
        echo "Users $User already exists."
    else
        useradd -m -d /home/"$User" -s /bin/bash "$User"
        su - "$User" -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh" > /dev/null 2>&1
        su - "$User" -c "ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ''" > /dev/null 2>&1
        su - "$User" -c "ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''" > /dev/null 2>&1
        su - "$User" -c "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys" > /dev/null 2>&1
        su - "$User" -c "cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys" > /dev/null 2>&1
        su - "$User" -c "chmod 600 ~/.ssh/authorized_keys" > /dev/null 2>&1
        if [ $? -eq 0 ]; then 
            echo "Account $User was successfully created"
            echo "$User Keys have successfully been created"
        fi
    fi
done	
echo 'Adding onto User dennis...'
        usermod -aG sudo dennis
        echo "$DENNIS_ADDITIONAL_KEY" >> /home/dennis/.ssh/authorized_keys
    	chown dennis:dennis /home/dennis/.ssh/authorized_keys
    	chmod 600 /home/dennis/.ssh/authorized_keys
    	if [ $? -eq 0 ]; then 
        echo "New configs have been added to dennis"
    else
        echo 'Configuration has failed'
fi
echo '---------------------------------------------'
echo 'Configuration complete!'
