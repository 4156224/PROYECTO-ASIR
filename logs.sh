#!/bin/bash
#===============================
#GESTOR DE LOGS PARA SERVIDORES
#===============================
admin="useradmin@10.0.0.6"
destino="/home/useradmin/logs"
servidor=$(hostname)
fecha=$(date +%Y-%m-%d)

case "$servidor" in
  router)
      LOG="/var/log/syslog"
      ;;
  dns)
      LOG="/var/log/syslog"
      ;;
  dhcp)
      LOG="/var/log/syslog"
      ;;
  apache)
      LOG="/var/log/apache2/error.log"
esac

#ENVIO DEL FICHERO DE LOG A USERADMIN
scp $LOG $admin:$destino/${servidor}_${fecha}_log.txt
