#INSTALAR APACHE2, PHP, PHPMYADMIN, MYSQL-CLIENT, MYSQL-SERVER
apt install php phpmyadmin mysql-client mysql-server apache2 -y
#ENTRAR A BASE DE DATOS Y CREAR USUARIO MASTER PARA MODIFICAR BASE DE DATOS
mysql
CREATE USER 'master'@'localhost' IDENTIFIED BY 'proyecto.master';
GRANT ALL PRIVILEGES on *.* to 'master'@'localhost';
FLUSH PRIVILEGES;

