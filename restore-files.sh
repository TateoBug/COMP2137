#!/bin/bash

run_hosts=false
run_hostname=false
run_netplan=false
run_runninghostname=false

while [[ $# -gt 0 ]]; do 
    case $1 in
        -hosts)
            run_hosts=true
            shift
            ;;
        -hostname)
            run_hostname=true
            shift
            ;;
        -netplan)
            run_netplan=true
            shift
            ;;
        -runninghostname)
            run_runninghostname=true
            shift
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

if ! $run_hosts && ! $run_hostname && ! $run_netplan && ! $run_runninghostname; then
    echo "No options specified. Do you want to:"
    echo "1. Run all options"
    echo "2. Choose specific options"
    echo "3. Exit"
    read -p "Enter your choice (1/2/3): " choice

    case $choice in
        1)
            run_hosts=true
            run_hostname=true
            run_netplan=true
            run_runninghostname=true
            ;;
        2)
            read -p "Do you want to restore /etc/hosts? (y/n): " hosts_choice
            if [[ "$hosts_choice" == "y" ]]; then
                run_hosts=true
            fi
            read -p "Do you want to restore /etc/hostname? (y/n): " hostname_choice
            if [[ "$hostname_choice" == "y" ]]; then
                run_hostname=true
            fi
            read -p "Do you want to restore /etc/netplan/10-lxc.yaml? (y/n): " netplan_choice
            if [[ "$netplan_choice" == "y" ]]; then
                run_netplan=true
            fi
            read -p "Do you want to restore the running hostname? (y/n): " runninghostname_choice
            if [[ "$runninghostname_choice" == "y" ]]; then
                run_runninghostname=true
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

if $run_hosts; then
    echo "Restoring /etc/hosts..."
    sudo cp /etc/hosts.bak /etc/hosts
fi

if $run_hostname; then
    echo "Restoring /etc/hostname..."
    sudo cp /etc/hostname.bak /etc/hostname
fi

if $run_netplan; then
    echo "Restoring /etc/netplan/10-lxc.yaml..."
    sudo cp /etc/netplan/10-lxc.yaml.bak /etc/netplan/10-lxc.yaml
fi

if $run_runninghostname; then
    echo "Restoring the running hostname..."
    sudo hostnamectl set-hostname $(cat /etc/hostname)
fi

