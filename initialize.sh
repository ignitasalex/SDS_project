#!/bin/bash

# Restart Snort service
sudo systemctl restart snort
sudo systemctl restart snort.service

# Clear Mininet cache
sudo mn -c

# Check if the interface s2-snort exists
if ip link show s2-snort &> /dev/null; then
  sudo ip link del name s2-snort
fi

# Add snort interface
sudo ip link add name s2-snort type dummy
sudo ip link set s2-snort up
