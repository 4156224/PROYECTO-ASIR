#!/bin/bash
#SCRIPT PARA INSTALAR SERVIDORES
#=============================================================================
# MAQUINAS POR SERVICIOS Y ROLES ACTIVOS
# ============================================================================
#PRF="user@10.0.0.2"     # Proxy + Firewall (squid, iptables, ?nftables?)
#DHCP="user@10.0.0.3"    # Servidor DHCP (isc-dhcp-server)
#ABBDD="user@10.0.0.4"   # Web + Base de datos (apache2, mariadb)
#DNS="user@10.0.0.5"     # DNS (bind9)
#==============================================================================
#TODOS TIENEN INSTALADO SSH Y LOS CONFIGURAREMOS MEDIANTE UNA MAQUINA DEBIAN ADMINISTRADORA
#IP: 10.0.0.6/8
#USUARIO: useradmin
#PASSWORD: admin
#USUARIO ROOT
#PASSWORD: root
#==============================================================================
#PARA PODER EJECUTAR EL SCRIPT CON TOTAL SEGURIDAD, EDITAR FICHERO DE 
#CONFIGURACION DE RED CON LA SIGUIENTE ESTRUCUTRA INICIAL PARA PODER 
#ENVIAR POR SSH EL SCRIPT:
#network:
#          version: 2
#          ethernets:
#            ens18:
#              dhcp4: false
#              addresses:
#                   - 10.0.0.X/8(IP DEL SERVIDOR EN CUESTION)
#==============================================================================
#CREAR LOS SERVIDORES EN ESTE ORDEN:
#1. ROUTER/FIREWALL
#2. DNS
#3. DHCP
#4. APACHEBBDD
#==============================================================================
#COMPROBAR QUE SE HA ACCEDIDO CON PRIVILEGIOS DE ADMINISTRADOR
#==============================================================================
if [ $UID -ne 0 ];then
  echo "NO SE TIENEN PRIVILEGIOS DE ADMINISTRADOR"
  exit 0
fi
#==============================================================================
#INSTALAR_ROUTER
#==============================================================================
instalar_router(){
 echo "***EDITANDO INTERFACES DE RED***"
 echo "network:
          version: 2
          ethernets:
            ens18:
              accept-ra: true
              dhcp4: true
              dhcp6: true
            ens19:
              dhcp4: false
              addresses:
                   - 10.0.0.2/24
              nameservers:
                   addresses:
                   - 10.0.0.5" > /etc/netplan/00-installer-config.yaml
  #UNA VEZ INSTALADO EL DNS CAMBIAR A IP DNS
  echo "***REINICIANDO INTERFACES DE RED***"
  netplan apply
  echo "***INSTALANDO PERSISTENCIA EN IPTABLES***"
  apt install iptables-persistent -y
  echo "***INSTALANDO IPTABLES PARA ENRUTAMIENTO***"
  apt install iptables -y
  echo "***modificando iptables y preparando forwarding***"
  echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
  sysctl -p
  iptables -F
  iptables -t nat -F
  #RUTA HACIA LA RED INTERNA
  ip route add 192.168.10.0/24 via 10.0.0.3
  #ENRUTAMIENTO
  iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o ens18 -j MASQUERADE
  iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o ens18 -j MASQUERADE
  #TRAFICO DE DATOS CON FORWARDING
  iptables -A FORWARD -i ens19 -o ens18 -j ACCEPT
  iptables -A FORWARD -i ens18 -o ens19 -m state --state RELATED,ESTABLISHED -j ACCEPT
  netfilter-persistent save
  echo "***INSTALADO SQUID***"
  apt install squid -y
  echo "*"
  echo "*"
  echo "*"
  echo "*"
  echo "---INSTALACION COMPLETADA---"
}
#==============================================================================
#INSTALAR DHCP
#==============================================================================
instalar_dhcp(){
  echo "***EDITANDO INTERFACES DE RED***"
  echo "network:
          version: 2
          ethernets:
            ens18:
              dhcp4: false
              addresses:
                   - 10.0.0.3/24
              routes:
                - to: default
                  via: 10.0.0.2
              nameservers:
                   addresses:
                   - 10.0.0.5
            ens19:
              addresses:
                   - 192.168.10.1/24
              nameservers:
                   addresses:
                   - 10.0.0.5" > /etc/netplan/00-installer-config.yaml
  echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
  sysctl -p
  echo "***REINICIANDO INTERFACES DE RED***"
  netplan apply
  apt install isc-dhcp-server -y
  echo "***DHCP INSTALADO***"
  echo "***CONFIGURANDO FICHERO DE DHCP.CONF***"
  echo " subnet 192.168.10.0 netmask 255.255.255.0 {
  range 192.168.10.20 192.168.10.100;
  option routers 192.168.10.1;
  option subnet-mask 255.255.255.0;
  option broadcast-address 192.168.10.255;
  option domain-name-servers 10.0.0.5, 8.8.8.8;
  }" > /etc/dhcp/dhcpd.conf
  echo "INTERFACESv4='ens19'" > /etc/default/isc-dhcp-server
  systemctl restart isc-dhcp-server
  echo "*"
  echo "*"
  echo "*"
  echo "*"
  echo "---INSTALACION COMPLETADA---"
  }
#==============================================================================
#INSTALAR_DNS
#==============================================================================
instalar_dns(){
  echo "***EDITANDO INTERFACES DE RED***"
  echo "network:
          version: 2
          ethernets:
            ens18:
              dhcp4: false
              addresses:
                   - 10.0.0.5/24
              routes:
                - to: default
                  via: 10.0.0.2
              nameservers:
                addresses:
                  - 8.8.8.8" > /etc/netplan/00-installer-config.yaml
  #CAMBIAR POSTERIORMENTE SERVIDOR DNS A 127.0.0.1
  echo "***REINICIANDO INTERFACES DE RED***"
  netplan apply
  apt install bind9 -y
  echo "***DNS INSTALADO***"
  echo "***MODIFICANDO FICHEROS DE CONFIGURACION***"
  ficheroconflocal='zone "proyecto.local" { type master; file "/etc/bind/proyecto.local"; }; 
                    zone "10.in-addr.arpa" { type master; file "/etc/bind/10.in-addr.arpa"; };
                    zone "incidencias.com" { type master; file "/etc/bind/incidencias.com"; };'
    #ARCHIVO QUE LE DICE A BIND9 QUE ZONAS EXISTEN
    echo "$ficheroconflocal" > /etc/bind/named.conf.local
    reenviadores='options {
                      directory "/var/cache/bind";
                      forwarders{
                          8.8.8.8;
                          };
                      allow-query {any;};
                      };'
    echo "$reenviadores" > /etc/bind/named.conf.options
    #ARCHIVO PARA RESOLVER NOMBRES DE DOMINIOS INTERNOS
    echo -e "\$TTL 604800
@    IN SOA proyecto.local. root.proyecto.local. (
        2
        604800
        86400
        2419200
        604800
)
    
@        IN  NS  dns.proyecto.local.
dns      IN  A   10.0.0.5
router   IN  A   10.0.0.2
dhcp     IN  A   10.0.0.3
apache   IN  A   10.0.0.4" > /etc/bind/proyecto.local
    #ARCHIVO DE PARA RESOLVER NOMBRES E IP INVERSA
    echo "\$TTL 604800
@    IN SOA proyecto.local. root.proyecto.local. (
        2
        604800
        86400
        2419200
        604800
)
    
@       IN  NS  dns.proyecto.local.
5.0.0   IN  PTR dns.proyecto.local.
2.0.0   IN  PTR router.proyecto.local.
3.0.0   IN  PTR dhcp.proyecto.local.
4.0.0   IN  PTR apache.proyecto.local." > /etc/bind/10.in-addr.arpa
          #INTRODUCIENDO ZONA DE INCIDENCIAS PARA QUE LA RESUELVA EL DNS LOCAL
    echo -e "\$TTL 604800
@   IN  SOA incidencias.com. root.incidencias.com. (
        2
        604800
        86400
        2419200
        604800
)
                
@       IN NS dns.incidencias.com.
dns     IN A 10.0.0.5
www     IN A 10.0.0.4" > /etc/bind/incidencias.com

echo "***EDITANDO INTERFACES DE RED***"
  #CAMBIAR DNS A 127.0.0.1
  echo "network:
          version: 2
          ethernets:
            ens18:
              dhcp4: false
              addresses:
                   - 10.0.0.5/24
              routes:
                - to: default
                  via: 10.0.0.2
              nameservers:
                addresses:
                  - 127.0.0.1" > /etc/netplan/00-installer-config.yaml
  #CAMBIAR POSTERIORMENTE SERVIDOR DNS A 127.0.0.1
  echo "***REINICIANDO INTERFACES DE RED***"
  netplan apply
  echo "***REINICIANDO BIND9***"
  systemctl restart bind9
    echo "*"
    echo "*"
    echo "*"
    echo "*"
    echo "---INSTALACION COMPLETADA---"
}
#==============================================================================
#INSTALAR_APACHEBBDD
#==============================================================================
instalar_apachebbdd(){
echo "***EDITANDO INTERFACES DE RED***"
echo "network:
          version: 2
          ethernets:
            ens18:
              dhcp4: false
              addresses:
                   - 10.0.0.4/24
              routes:
              - to: default
                via: 10.0.0.2
              nameservers:
                   addresses:
                   - 10.0.0.5" > /etc/netplan/00-installer-config.yaml
  echo "***REINICIANDO INTERFACES DE RED***" 
  netplan apply
  echo "***INSTALANDO BBDD Y APACHE***"
  apt install apache2 mariadb-server php libapache2-mod-php php-mysql phpmyadmin python3-requests -y
  echo "*"
  echo "*"
  echo "*"
  echo "*"
  echo "---INSTALACION COMPLETADA---"
}

instalar_apachebbdd2(){
    apt update
    echo "***EDITANDO INTERFACES DE RED***"
    echo "network:
          version: 2
          ethernets:
            ens18:
              dhcp4: false
              addresses:
                   - 10.0.0.4/24
              routes:
                - to: default
                  via: 10.0.0.2
              nameservers:
                   addresses:
                   - 10.0.0.5" > /etc/netplan/00-installer-config.yaml
    echo "***REINICIANDO INTERFACES DE RED***"
    netplan apply

    echo "***INSTALANDO BBDD, APACHE, PHP Y DEPENDENCIAS PARA TELEGRAM***"
    DEBIAN_FRONTEND=noninteractive apt install -y \
        apache2 mariadb-server mariadb-client \
        php libapache2-mod-php php-mysql phpmyadmin \
        python3-requests

    echo "***CONFIGURANDO BASE DE DATOS Y PAGINA WEB***"
    # Usuario y contraseña que usa tu conexion.php
    usuario_app="admin"
    passwd_app="admin"
    db_name="gestion_incidencias"

    # Crear BD, usuario y dar permisos (idempotente)
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS $db_name;
CREATE USER IF NOT EXISTS '$usuario_app'@'localhost' IDENTIFIED BY '$passwd_app';
GRANT ALL PRIVILEGES ON $db_name.* TO '$usuario_app'@'localhost';
FLUSH PRIVILEGES;
EOF

    # Crear tablas y usuarios de prueba
    mysql -u root $db_name << 'EOF'
CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    rol ENUM('usuario', 'admin') DEFAULT 'usuario'
);

CREATE TABLE IF NOT EXISTS incidencias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    descripcion TEXT NOT NULL,
    ip_usuario VARCHAR(45),
    estado ENUM('pendiente', 'resuelta') DEFAULT 'pendiente',
    usuario_id INT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- Usuarios de prueba con contraseña plana (se hasheará después)
INSERT IGNORE INTO usuarios (nombre, password, rol) VALUES
('Andres', '1234', 'admin'),
('salva', '1234', 'usuario'),
('daniel', '1234', 'usuario');
EOF

    # Hashear automáticamente las contraseñas de prueba
    echo "<?php
\$hash = password_hash('1234', PASSWORD_DEFAULT);
\$sql = \"UPDATE usuarios SET password = '\$hash' WHERE password = '1234'\";
\$conn = new mysqli('localhost', 'root', '', '$db_name');
\$conn->query(\$sql);
?>" > /tmp/hashear_tmp.php

    php /tmp/hashear_tmp.php
    rm /tmp/hashear_tmp.php

    echo "*"
    echo "*"
    echo "*"
    echo "*"
    echo "---INSTALACION COMPLETADA---"
    echo "Base de datos creada: $db_name"
    echo "Usuario aplicación: $usuario_app / $passwd_app"
    echo "Las contraseñas de prueba ya están hasheadas"
    echo "Sube los archivos .php y bot.py a /var/www/html/"
}
#==============================================================================
                          #***** MENU DE OPCIONES *****#
#==============================================================================
echo "***SCRIPT DE INSTALACION DE SERVIDORES***"
read -p "Introduce el tipo de servidor que quieres instalar(dhcp/dns/router/apachebbdd): " p1
if [ "$p1" == "dhcp" ];then
  instalar_dhcp
elif [ "$p1" == "dns" ];then
  instalar_dns
elif [ "$p1" == "router" ];then
  instalar_router
elif [ "$p1" == "apachebbdd2" ];then
  instalar_apachebbdd2
else
  echo "NO HAS INTRODUCIDO NINGUNO DE LOS SERVIDORES NOMBRADOS"
  exit 0
fi
