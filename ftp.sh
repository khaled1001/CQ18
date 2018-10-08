#!/bin/bash

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