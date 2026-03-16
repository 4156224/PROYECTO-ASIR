# PROYECTO-ASIR
Proyecto ASIR para final del 2º curso.
# -------------------------------------
Creadores
# -------------------------------------
- Salvador Manrubia Carrascosa
- Daniel Garcia Monreal
- Andrés Pérez Ramírez
# =====================================
INSTALL.SH o INSTALLV2.SH
# =====================================
Este script nos permite automatizar la instalación de servidores.
Para poder administrar dichos servidores con nuestra máquina Administradora, debemos previamente configurar una interfaz de red, obligatoriamente la misma que le vayamos a poner al servidor en cuestión, para poder acceder mediante canal SSH con nuestro Administrador e instalar el script.
Nuesta máquina administradora tendrá acceso a la LAN de servidores y a la WAN que da acceso a internet para poder instalar desde GitHub y SSH los repositorios.
Los servidores son los siguientes:
- Servidor Firewall que actuara como router, para controlar el tráfico en la LAN, y el acceso a internet de la Subred.
- Servidor DNS, para resolver nombres de dominio.
- Servidor DHCP, para controlar distintos Pc's dentro de una subred.
- Servidor Apache y MariaDB, para permitir a los administradores de la "EMPRESA" para la que va dirigida los servidores. poder poner incidencias sobre los servidores mediante interfaz web.
# ====================================
ADMIN_COLLECTIVO.SH o GESTOR.SH
# ====================================
Con este script ofrecemos un menú sencillo para realizar operaciones de mantenimiento  comunes en todos los servidores o de forma selectiva por rol.
Conexión SSH, actualiza los servidores y reinicia servicios.
Nuestro objetivo es centralizar operaciones de mantenimiento, evitar conexión manual al servidor y posibilidad de escalabilidad(estado del servidor, logs...)
#=====================================
SERVICIOS_VIRTUALES.SH
#=====================================
Con este srcipt agilizamos la creación de un servidor virtual en el que alojar páginas web relacionadas con nuestro objetivo de trabajo.
Crea carpetas, dita ficheros de configuración y habilita los sitios web, reiniciando por última instancia el servicio web.
#=====================================
PHP
#=====================================
También tenemos aquí nuestros ficheros .php, en el que ofrecemos nuestro gestor de incidencias para empresas.
Login, consultar incidencias, gestionar incidencias, conectar como administrador...
