# PROYECTO-ASIR
Proyecto ASIR para final del 2º curso.
# -------------------------------------
Creadores
# -------------------------------------
Salvador Manrubia Carrascosa
Daniel Garcia Monreal
# =====================================
INSTALL.SH
# =====================================
Este script nos permite automatizar la instalación de servidores.
Para poder administrar dichos servidores con nuestro Administrador, debemos previamente configurar una interfaz de red, obligatoriamente la misma que le vayamos a poner al servidor en cuestión, para poder acceder mediante canal SSH con nuestro Administrador e instalar el script.
Nuesta máquina administradora tendrá acceso a la LAN de servidores y a la WAN que da acceso a internet para poder instalar desde GitHub y SSH los repositorios.
Los servidores son los siguientes:
- Servidor Firewall que actuara como router, para controlar el tráfico en la LAN, y el acceso a internet de la Subred.
- Servidor DNS, para resolver nombres de dominio.
- Servidor DHCP, para controlar distintos Pc's dentro de una subred.
- Servidor Apache y MariaDB, para permitir a los administradores de la "EMPRESA" para la que va dirigida los servidores. poder poner incidencias sobre los servidores mediante interfaz web.

