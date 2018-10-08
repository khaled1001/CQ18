#!/bin/bash

# Simply takes an argument and runs iptables
echo "Blocking IP $1..."
sudo iptables -A INPUT -s $1 -j DROP
sudo iptables -A OUTPUT -s $1 -j DROP