#!/bin/bash

backup_hosts=false
backup_hostname=false
backup_netplan=false
backup_runninghostname=false

while [[ $# -gt 0 ]]; do 
    case $1 in
        -hosts)
            backup_hosts=true
            shift
            ;;
        -hostname)
            backup_hostname=true
            shift
            ;;
        -netplan)
            backup_netplan=true
            shift
            ;;
        -runninghostname)
            backup_runninghostname=true
            shift
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

if ! $backup_hosts && ! $backup_hostname && ! $backup_netplan && ! $backup_runninghostname; then
    echo "No options specified. Do you want to:"
    echo "1. Backup all options"
    echo "2. Choose specific options"
    echo "3. Exit"
    read -p "Enter your choice (1/2/3): " choice

    case $choice in
        1)
            backup_hosts=true
            backup_hostname=true
            backup_netplan=true
            backup_runninghostname=true
            ;;
        2)
            read -p "Do you want to backup /etc/hosts? (y/n): " hosts_choice
            if [[ "$hosts_choice" == "y" ]]; then
                backup_hosts=true
            fi
            read -p "Do you want to backup /etc/hostname? (y/n): " hostname_choice
            if [[ "$hostname_choice" == "y" ]]; then
                backup_hostname=true
            fi
            read -p "Do you want to backup /etc/netplan/10-lxc.yaml? (y/n): " netplan_choice
            if [[ "$netplan_choice" == "y" ]]; then
                backup_netplan=true
            fi
            read -p "Do you want to backup the running hostname? (y/n): " runninghostname_choice
            if [[ "$runninghostname_choice" == "y" ]]; then
                backup_runninghostname=true
            fi
            ;;
        3)
            echo "Exiting without making any changes."
            exit 0
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

if $backup_hosts; then
    echo "Backing up /etc/hosts..."
    sudo cp /etc/hosts /etc/hosts.bak
fi

if $backup_hostname; then
    echo "Backing up /etc/hostname..."
    sudo cp /etc/hostname /etc/hostname.bak
fi

if $backup_netplan; then
    echo "Backing up /etc/netplan/10-lxc.yaml..."
    sudo cp /etc/netplan/10-lxc.yaml /etc/netplan/10-lxc.yaml.bak
fi

if $backup_runninghostname; then
    echo "Backing up the running hostname..."
    sudo hostnamectl status | grep "Static hostname" | awk '{print $3}' | sudo tee /etc/hostname.bak > /dev/null
fi

