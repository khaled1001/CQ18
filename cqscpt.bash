##########Set-up_Basic######################################################
##########Start of scripts##################################################
echo ""
echo ""
echo "###########################################"
echo "####\ \ \           Best          / / /####"
echo "#####==-->         Script        <--==#####"
echo "####/ / /           Ever          \ \ \####"
echo "###########################################"
	
sudo apt-get update -y && apt-get upgrade -y #update and upgrade all packages


###SSH

#Allowing our IPs to ssh to server, dropping everything else
echo "Please enter IP of User 1..."
read ip1
echo "Please enter IP of User 2..."
read ip2
echo "Please enter IP of User 3..."
read ip3
#RETRIEVE IPs of 3 computers before proceeding (Manual)
sudo iptables -A INPUT -p tcp -s $ip1 --dport 22 -j ACCEPT #allow our IPs to access ssh
sudo iptables -A INPUT -p tcp -s $ip2 --dport 22 -j ACCEPT #allow our IPs to access ssh
sudo iptables -A INPUT -p tcp -s $ip3 --dport 22 -j ACCEPT #allow our IPs to access ssh
sudo iptables -A INPUT -p tcp --dport 22 -j DROP

#RETRIEVE USERNAMES of 3 computers before proceeding #> Updated <#
echo "Please enter the name of user 1"
read usr1
echo "Please enter the name of user 2"
read usr2
echo "Please enter the name of user 3"
read usr3
sudo echo "AllowUsers $usr1 $usr2 $usr3" >> /etc/ssh/sshd_config 

#Prevent brute-force attacks (SSH only, can be generalized to other ports) #> Updated <#
echo "Please enter the name of your network adapter:"
read netAd
sudo iptables -I INPUT -p tcp --dport 22 -i $netAd -m state --state NEW -m recent --set
sudo iptables -I INPUT -p tcp --dport 22 -i $netAd -m state --state NEW -m recent --update --seconds 222 --hitcount 3 -j DROP

sudo service ssh restart


###FTP

sudo apt-get install vsftpd #?
sudo service vsftpd start #?
echo "local_root=/srv/ftp" >> /etc/vsftpd.conf

#Create SSL certificate to encrypt FTP service
sudo mkdir /etc/ssl/certificates
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/certificates/vsftpd.pem -out /etc/ssl/certificates/vsftpd.pem
sudo echo "rsa_cert_file=/etc/ssl/certificates/vsftpd.pem" >> /etc/vsftpd.conf
sudo echo "rsa_private_key_file=/etc/ssl/certificates/vsftpd.pem" >> /etc/vsftpd.conf
sudo echo "ssl_enable=YES" >> /etc/vsftpd.conf
sudo echo "allow_anon_ssl=NO" >> /etc/vsftpd.conf
sudo echo "force_local_data_ssl=YES" >> /etc/vsftpd.conf
sudo echo "force_local_logins_ssl=YES" >> /etc/vsftpd.conf
sudo echo "ssl_tlsv1=YES" >> /etc/vsftpd.conf
sudo echo "ssl_sslv2=NO" >> /etc/vsftpd.conf
sudo echo "ssl_sslv3=NO" >> /etc/vsftpd.conf
sudo echo "require_ssl_reuse=NO" >> /etc/vsftpd.conf
sudo echo "ssl_ciphers=HIGH" >> /etc/vsftpd.conf

#Write Protection
sudo sed -i "s/anonymous_enable=YES/anonymous_enable=NO/" >> /etc/vsftpd.conf
#sudo sed -i "s/write_enable=YES/#write_enable=YES/" >> /etc/vsftpd.conf
sudo sed -i "s/anon_upload_enable=YES/#anon_upload_enable=YES/" >> /etc/vsftpd.conf
sudo sed -i "s/anon_mkdir_write_enable=YES/#anon_mkdir_write_enable=YES/" >> /etc/vsftpd.conf

sudo service vsftpd restart

#Strengthen password policy
sudo apt-get install libpam-cracklib
sudo echo "auth required pam_tally2.so deny=3 unlock_time=60 even_deny_root_account silent" >> /etc/pam.d/common-auth
sudo sed -i "s/password requisite pam_cracklib.so retry=3 minlen=8 difok=3/password requisite pam_cracklib.so retry=3 minlen=10 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 reject_username/" >> /etc/pam.d/common-password

#Prevent brute-force attacks (FTP only, can be generalized to other ports) #> UPDATED <#
sudo iptables -I INPUT -p tcp --dport 21 -i $netAd -m state --state NEW -m recent --set
sudo iptables -I INPUT -p tcp --dport 21 -i $netAd -m state --state NEW -m recent --update --seconds 300 --hitcount 3 -j DROP


###APACHE2

sudo systemctl start apache2
sudo systemctl enable apache2

#installing modsecurity2 package
sudo apt-get install libapache2-mod-security2
cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
sudo sed -i "s/SecRuleEngine DetectionOnly/SecRuleEngine on/" >> /etc/modsecurity/modsecurity.conf
sudo systemctl restart apache2

#Installing up-to-date modsecurity ruleset
sudo rm -rf /usr/share/modsecurity-crs
sudo git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /usr/share/modsecurity-crs
cd /usr/share/modsecurity-crs
cp crs-setup.conf.example crs-setup.conf
#sudo on security2.conf file
sudo service apache2 restart

#HTTP-Only Cookies
sudo a2enmod headers
sudo service apache2 restart
sudo echo "Header edit Set-Cookie ^(.*)$ $1;HttpOnly;Secure" >> /etc/apache2/conf-available/security.conf
sudo service httpd restart

#Disable Auto-indexing
sudo a2dismod autoindex
sudo service apache2 restart