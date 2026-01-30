#INSTALAR APACHE2, PHP, PHPMYADMIN, MYSQL-CLIENT, MYSQL-SERVER
apt install php phpmyadmin mysql-client mysql-server apache2 -y
#ENTRAR A BASE DE DATOS Y CREAR USUARIO MASTER PARA MODIFICAR BASE DE DATOS
mysql
CREATE USER 'master'@'localhost' IDENTIFIED BY 'proyecto.master';
GRANT ALL PRIVILEGES on *.* to 'master'@'localhost';
FLUSH PRIVILEGES;
quit
nano /etc/network/interfaces > echo " auto enp0s3
iface enp0s3 inet static
 address 172.116.1.13
 gateway 172.116.1.1
 dns-nameservers 172.116.1.12 8.8.8.8"
 systemctl service restart networking
 mkdir /var/www/html/paginawebnegocio
 touch /var/www/html/paginawebnegocio/index.html
 touch /var/www/html/paginawebnegocio/login.html
 #CREAR VIRTUALHOST Y DIRECTORIO PARA LA CARPETA PAGINAWEBNEGOCIO PARA ACCEDER A LA MISMA
 
