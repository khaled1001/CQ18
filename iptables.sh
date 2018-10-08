#!/bin/bash

# Interface
INTERFACE="eth0"

# Flush all rules
echo "Flushing IPTables..."
sudo iptables -F
sudo iptables -X
sudo iptables -Z

# Allow internal traffic
iptables -A INPUT -i lo -j ACCEPT

# Ports of services that need to be open WITHOUT ssh
ports=(80, 443, 21)

for port in "${ports[@]}"
do
	:
	echo "iptables -A INPUT -p tcp --dport $port -j ACCEPT"
	iptables -A INPUT -p tcp --dport $port -j ACCEPT
done

ssh_whitelist=("1.1.1.1" "8.8.8.8")

for $ip in "${ssh_whitelist[@]}"
do
	:
	echo "iptables -A INPUT -p tcp -s $ip --dport 22 -j ACCEPT"
	iptables -A INPUT -p tcp -s $ip --dport 22 -j ACCEPT
done

# SSH bruteforce disable
iptables -A INPUT -p TCP --dport 22 -i $INTERFACE -m state --state NEW -m recent --set
iptables -A INPUT -p TCP --dport 22 -i $INTERFACE -m state --state NEW -m recent --update --second 300 --hitcount 3 -j DROP

# Allow established connections
iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  
# Allow outgoing connections
iptables -P OUTPUT ACCEPT

# Drop all at the end
iptables -P INPUT DROP

echo "Done!"