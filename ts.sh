#!/bin/bash

interface=$1
echo "Starting Termshark on ${interface}"
sudo /var/lib/snapd/snap/bin/termshark -i ${interface} -f "udp port 47809"
