#!/bin/bash

# Start with apache2, install stuff
sudo apt install libapache2-mod-security2 libapache2-mod-evasive git libpam-cracklib -y

# Hide Apache2 version
echo "ServerSignature Off" >> /etc/apache2/apache2.conf
echo "ServerTokens Prod" >> /etc/apache2/apache2.conf

# Remove ETags
echo "FileETag None" >> /etc/apache2/apache2.conf

# Disable Directory Browsing
a2dismod -f autoindex

# Secure root directory
echo "<Directory />" >> /etc/apache2/conf-available/security.conf
echo "Options -Indexes" >> /etc/apache2/conf-available/security.conf
echo "AllowOverride None" >> /etc/apache2/conf-available/security.conf
echo "Order Deny,Allow" >> /etc/apache2/conf-available/security.conf
echo "Deny from all" >> /etc/apache2/conf-available/security.conf
echo "</Directory>" >> /etc/apache2/conf-available/security.conf

# Secure html directory
echo "<Directory /var/www/html>" >> /etc/apache2/conf-available/security.conf
echo "Options -Indexes -Includes" >> /etc/apache2/conf-available/security.conf
echo "AllowOverride None" >> /etc/apache2/conf-available/security.conf
echo "Order Allow,Deny" >> /etc/apache2/conf-available/security.conf
echo "Allow from All" >> /etc/apache2/conf-available/security.conf
echo "</Directory>" >> /etc/apache2/conf-available/security.conf

# Setup mod_evasive
mkdir /var/log/mod_evasive 
cd ~/CQScripts
mv ./evasive.conf /etc/apache2/mods-enabled/evasive.conf

# Enable headers module
a2enmod headers

# Enable HttpOnly and Secure flags
echo "Header edit Set-Cookie ^(.*)\$ \$1;HttpOnly;Secure" >> /etc/apache2/conf-available/security.conf

# Clickjacking Attack Protection
echo "Header always append X-Frame-Options SAMEORIGIN" >> /etc/apache2/conf-available/security.conf

# XSS Protection
echo "Header set X-XSS-Protection \"1; mode=block\"" >> /etc/apache2/conf-available/security.conf

# MIME sniffing Protection
echo "Header set X-Content-Type-Options: \"nosniff\"" >> /etc/apache2/conf-available/security.conf

# Prevent Cross-site scripting and injections
echo "Header set Content-Security-Policy \"default-src 'self';\"" >> /etc/apache2/conf-available/security.conf

# Prevent DoS attacks - Limit timeout
sed -i "s/Timeout 300/Timeout 60/" /etc/apache2/apache2.conf

# Mod security
mv ./modsecurity.conf /etc/modsecurity/modsecurity.conf
sudo service apache2 restart
rm -rf /usr/share/modsecurity-crs
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /usr/share/modsecurity-crs
cd /usr/share/modsecurity-crs
mv crs-setup.conf.example crs-setup.conf
mv ~/CQScripts/security2.conf /etc/apache2/mods-enabled/security2.conf
sudo service apache2 restart

# SSH
echo "Fixing SSH..."

# Set /etc/ssh/sshd_config ownership and access permissions
chown root:root /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config

# Protocol 2
echo "Protocol 2" >> /etc/ssh/sshd_config

# Set SSH LogLevel to INFO
sed -i "/LogLevel.*/s/^#//g" /etc/ssh/sshd_config

# Set SSH MaxAuthTries to 3
sed -i "s/#MaxAuthTries 6/MaxAuthTries 3/g" /etc/ssh/sshd_config

# Enable SSH IgnoreRhosts
sed -i "/IgnoreRhosts.*/s/^#//g" /etc/ssh/sshd_config

# Disable SSH HostbasedAuthentication
sed -i "/HostbasedAuthentication.*no/s/^#//g" /etc/ssh/sshd_config

# Disable SSH root login
sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin no/g" /etc/ssh/sshd_config

# Deny Empty Passwords
sed -i "/PermitEmptyPasswords.*no/s/^#//g" /etc/ssh/sshd_config

# Deny Users to set environment options through the SSH daemon
sed -i "/PermitUserEnvironment.*no/s/^#//g" /etc/ssh/sshd_config

service ssh restart

# FTP

# Filename
CONFIG_FILE="/etc/vsftpd.conf"
SSL_DIR="/etc/ssl/certificates"
C_FLAG=""

# Edit existing conf options
echo "Replacing values..."
sed $C_FLAG -i "s/\(anonymous_enable *= *\).*/\1NO/" $CONFIG_FILE
sed $C_FLAG -i "s/\(local_umask *= *\).*/\1022/" $CONFIG_FILE

# Create SSL cert
echo "Creating certificates..."
mkdir -p $SSL_DIR
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=AE/ST=Dubai/L=Dubai/O=BlueTeam/OU=BlueTeam/CN=blueteam.com/emailAddress=noreply@blueteam.com" -keyout $SSL_DIR/vsftpd.pem -out $SSL_DIR/vsftpd.pem

# Edit conf
echo "Appending conf file..."
echo "write_enable=YES" >> $CONFIG_FILE
echo "rsa_cert_file=$SSL_DIR/vsftpd.pem" >> $CONFIG_FILE
echo "rsa_private_key_file=$SSL_DIR/vsftpd.pem" >> $CONFIG_FILE
echo "ssl_enable=YES" >> $CONFIG_FILE
echo "allow_anon_ssl=NO" >> $CONFIG_FILE
echo "force_local_data_ssl=YES" >> $CONFIG_FILE
echo "force_local_logins_ssl=YES" >> $CONFIG_FILE
echo "ssl_tlsv1=YES" >> $CONFIG_FILE
echo "ssl_sslv2=NO" >> $CONFIG_FILE
echo "ssl_sslv3=NO" >> $CONFIG_FILE
echo "require_ssl_reuse=NO" >> $CONFIG_FILE
echo "ssl_ciphers=HIGH" >> $CONFIG_FILE
echo "anon_upload_enable=NO" >> $CONFIG_FILE
echo "anon_mkdir_write_enable=NO" >> $CONFIG_FILE

# Restart ftp
echo "Restarting vsftpd..."
service vsftpd restart

echo "Testing if vsftpd still works..."
service vsftpd status

# Password hardening
mv /etc/pam.d/common-auth /etc/pam.d/common-auth.old
cd ~/CQScripts
mv ./common-auth /etc/pam.d/common-auth
mv /etc/pam.d/common-password /etc/pam.d/common-password.old
mv ./common-password /etc/pam.d/common-password