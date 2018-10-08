#!/bin/bash

sudo apt install lynis tiger rkhunter fail2ban -y

echo "Updating rkhunter..."
sudo rkhunter --update
sudo rkhunter --produpd

echo "Running rkhunter..."
sudo rkhunter -c --enable all --disable none

echo "Running lynis tests..."
sudo lynis audit system -Q