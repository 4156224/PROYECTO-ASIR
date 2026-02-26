#!/bin/bash
#==============================================================================
#SCRIPT PARA CREAR SERVIDORES VIRTUALES
#==============================================================================
#COMPROBAR QUE SE HA ACCEDIDO CON PRIVILEGIOS DE ADMINISTRADOR
#==============================================================================
if [ $UID -ne 0 ];then
  echo "NO SE TIENEN PRIVILEGIOS DE ADMINISTRADOR"
  exit 0
fi
#==============================================================================
#CREAR, HABILITAR Y GESTIONAR SERVIDOR VIRTUAL JUNTO CON FICHEROS
#==============================================================================
mkdir /var/www/html/incidencias
touch /etc/apache2/sites-available/incidencias.conf
echo "<VirtualHost *:80>
              ServerName www.incidencias.com
              ServerAlias incidencias.com
              DocumentRoot /var/www/html/incidencias
              <Directory /var/www/html/incidencias>
                      DirectoryIndex option.php
                      Options Indexes FollowSymLinks MultiViews
                      AllowOverride All
                      Require all granted
              </Directory>
      </VirtualHost>" >> /etc/apache2/sites-available/incidencias.conf
a2ensite incidencias.conf
systemctl restart apache2
#==============================================================================
#DEBEMOS INCLUIR LOS FICHEROS QUE NECESITAMOS PARA LA PAGINA WEB EN 
#EL DIRECTORIO: /var/www/html/incidencias
#LO PODEMOS HACER MEDIANTE GITHUB, CLONANDO LOS FICHEROS QUE ESTARAN EN EL 
#REPOSITORIO Y MOVIENDOLOS DE SITIO
#==============================================================================
