apt install bind9
#MODIFICAR INTERFACES DE RED
nano /etc/network/interfaces > echo " auto enp0s3
iface enp0s3 inet static
 address 172.116.1.12
 gateway 172.116.1.1
 dns-nameservers 127.0.0.1 8.8.8.8"
 systemctl service restart networking
 
